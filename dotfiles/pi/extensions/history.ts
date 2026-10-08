/**
 * Cross-session prompt history for the current working directory.
 *
 * - Up/Down: prompts from previous sessions are preloaded into the editor history.
 * - Ctrl+R: searchable picker above the editor; Enter puts the prompt in the editor.
 */

import { relative } from "node:path";
import {
  CustomEditor,
  type ExtensionAPI,
  type ExtensionContext,
  type KeybindingsManager,
  SessionManager,
  type Theme,
} from "@earendil-works/pi-coding-agent";
import {
  type Component,
  type Focusable,
  Input,
  Key,
  matchesKey,
  SelectList,
  type TUI,
  truncateToWidth,
  visibleWidth,
} from "@earendil-works/pi-tui";

const MAX_PROMPTS = 500;
const MAX_VISIBLE_ROWS = 10;
const WIDGET_KEY = "history.picker";

interface Prompt {
  text: string;
  timestamp: number;
}

export default function(pi: ExtensionAPI) {
  let previous: Prompt[] = [];
  type EditorFactory = NonNullable<ReturnType<ExtensionContext["ui"]["getEditorComponent"]>>;
  let baseFactory: EditorFactory | undefined;
  let ownFactory: EditorFactory | undefined;

  const installEditor = (ctx: ExtensionContext) => {
    // Wrap the other extensions' editor once, not our own wrapper from an earlier session.
    const current = ctx.ui.getEditorComponent();
    if (current !== ownFactory) baseFactory = current;
    ownFactory = (tui, theme, keybindings) => {
      const editor = baseFactory?.(tui, theme, keybindings) ?? new CustomEditor(tui, theme, keybindings, { embedWorkingStatus: true });
      for (const prompt of [...previous].reverse()) editor.addToHistory?.(prompt.text);
      return editor;
    };
    ctx.ui.setEditorComponent(ownFactory);
  };

  pi.on("session_start", (_event, ctx) => {
    void loadPrompts(ctx.cwd).then((prompts) => {
      previous = prompts;
      installEditor(ctx);
    });
  });

  pi.registerShortcut("ctrl+r", {
    description: "Search prompt history",
    handler: async (ctx) => {
      const prompts = dedupe([...branchPrompts(ctx), ...previous]);
      if (prompts.length === 0) {
        ctx.ui.notify("No prompt history found.", "info");
        return;
      }
      const selected = await openPicker(ctx, prompts);
      if (selected !== null) ctx.ui.setEditorText(selected);
    },
  });
}

async function openPicker(ctx: ExtensionContext, prompts: Prompt[]): Promise<string | null> {
  let tui: TUI | undefined;
  try {
    // A zero-size overlay takes keyboard focus; the visible picker is a widget so the editor stays on screen.
    return await ctx.ui.custom<string | null>(
      (_tui, _theme, keybindings, done) => {
        let picker: HistoryPicker | undefined;
        ctx.ui.setWidget(
          WIDGET_KEY,
          (widgetTui, theme) => {
            tui = widgetTui;
            picker = new HistoryPicker(widgetTui, theme, keybindings, prompts, ctx.cwd, done);
            return picker;
          },
          { placement: "aboveEditor" },
        );
        if (!picker) throw new Error("history picker widget was not created");
        const target = picker;
        return {
          handleInput: (data: string) => target.handleInput(data),
          render: () => [],
          invalidate: () => target.invalidate(),
        };
      },
      { overlay: true, overlayOptions: { anchor: "top-left", width: 1 } },
    );
  } finally {
    ctx.ui.setWidget(WIDGET_KEY, undefined);
    tui?.requestRender();
  }
}

class HistoryPicker implements Component, Focusable {
  private readonly input: Input;
  private list: SelectList;
  private filtered: Prompt[];
  private selected = 0;
  private focusedValue = false;

  constructor(
    private readonly tui: TUI,
    private readonly theme: Theme,
    private readonly keybindings: KeybindingsManager,
    private readonly prompts: Prompt[],
    private readonly cwd: string,
    private readonly done: (text: string | null) => void,
  ) {
    this.input = new Input({
      prompt: "Search: ",
      placeholder: "prompt text",
      placeholderStyle: (text) => theme.fg("dim", text),
    });
    this.filtered = prompts;
    this.list = this.createList();
  }

  get focused(): boolean {
    return this.focusedValue;
  }

  set focused(value: boolean) {
    this.focusedValue = value;
    this.input.focused = value;
  }

  handleInput(data: string): void {
    const kb = this.keybindings;
    if (kb.matches(data, "tui.select.cancel")) return this.done(null);
    if (kb.matches(data, "tui.select.confirm")) return this.done(this.filtered[this.selected]?.text ?? null);
    if (matchesKey(data, Key.ctrl("p")) || kb.matches(data, "tui.select.up")) this.move(-1);
    else if (matchesKey(data, Key.ctrl("n")) || kb.matches(data, "tui.select.down")) this.move(1);
    else if (kb.matches(data, "tui.select.pageUp")) this.move(-this.visibleRows());
    else if (kb.matches(data, "tui.select.pageDown")) this.move(this.visibleRows());
    else {
      const before = this.input.getValue();
      this.input.handleInput(data);
      if (this.input.getValue() !== before) {
        this.filtered = search(this.prompts, this.input.getValue());
        this.selected = 0;
        this.list = this.createList();
      }
    }
    this.tui.requestRender();
  }

  private move(delta: number): void {
    const count = this.filtered.length;
    if (count === 0) return;
    this.selected = (((this.selected + delta) % count) + count) % count;
    this.list.setSelectedIndex(this.selected);
  }

  private visibleRows(): number {
    return Math.max(1, Math.min(MAX_VISIBLE_ROWS, this.tui.terminal.rows - 12));
  }

  render(width: number): string[] {
    const { theme } = this;
    const border = (text: string) => theme.fg("borderMuted", text);
    const panel = Math.max(4, width - 2);
    const inner = panel - 4;
    const row = (content: string) => {
      const text = truncateToWidth(content, inner, "");
      return ` ${border("│")} ${text}${" ".repeat(Math.max(0, inner - visibleWidth(text)))} ${border("│")} `;
    };

    const title = theme.bold(theme.fg("accent", "Prompt History"));
    const info = theme.fg("muted", displayCwd(this.cwd));
    const head = `${border("─ ")}${title}${border(" ")}`;
    const tail = `${border(" ")}${info}${border(" ─")}`;
    const fill = Math.max(0, panel - 2 - visibleWidth(head) - visibleWidth(tail));
    const top = truncateToWidth(`${border("╭")}${head}${border("─".repeat(fill))}${tail}${border("╮")}`, panel, "");

    const body = this.filtered.length ? this.list.render(inner) : [theme.fg("warning", "No matching prompts.")];
    const hints = ["Enter apply", "Ctrl+P/N/Arrows move", "PgUp/PgDn page", "Esc cancel"].join(" · ");

    return [
      ` ${top} `,
      row(this.input.render(inner)[0] ?? ""),
      ...body.map(row),
      row(theme.fg("dim", hints)),
      ` ${border(`╰${"─".repeat(panel - 2)}╯`)} `,
    ];
  }

  invalidate(): void {
    this.input.invalidate();
    this.list.invalidate();
  }

  private createList(): SelectList {
    const { theme } = this;
    const query = this.input.getValue();
    const items = this.filtered.map((prompt, i) => ({
      value: String(i),
      label: `${theme.fg("muted", dateLabel(prompt.timestamp))} ${theme.fg("dim", "·")} ${highlight(oneLine(prompt.text), query, theme)}`,
    }));
    return new SelectList(
      items,
      this.visibleRows(),
      {
        selectedPrefix: (text) => theme.fg("accent", text),
        selectedText: (text) => theme.bg("selectedBg", theme.fg("text", text)),
        description: (text) => theme.fg("muted", text),
        scrollInfo: (text) => theme.fg("dim", text),
        noMatch: (text) => theme.fg("warning", text),
      },
      { truncatePrimary: ({ text, maxWidth }) => truncateToWidth(text, maxWidth, "…") },
    );
  }
}

function tokens(query: string): string[] {
  return query.trim().toLowerCase().split(/\s+/).filter(Boolean);
}

function search(prompts: Prompt[], query: string): Prompt[] {
  const terms = tokens(query);
  return prompts.filter((prompt) => {
    const text = prompt.text.toLowerCase();
    return terms.every((term) => text.includes(term));
  });
}

function highlight(text: string, query: string, theme: Theme): string {
  const lower = text.toLowerCase();
  const marked = new Set<number>();
  for (const term of tokens(query)) {
    for (let at = lower.indexOf(term); at >= 0; at = lower.indexOf(term, at + term.length)) {
      for (let i = at; i < at + term.length; i++) marked.add(i);
    }
  }
  let out = "";
  for (let i = 0; i < text.length;) {
    const on = marked.has(i);
    let j = i;
    while (j < text.length && marked.has(j) === on) j++;
    const part = text.slice(i, j);
    out += on ? theme.fg("searchMatchText", theme.bold(part)) : part;
    i = j;
  }
  return out;
}

function oneLine(text: string): string {
  return text.replace(/\s+/g, " ").trim();
}

function dateLabel(timestamp: number): string {
  if (!Number.isFinite(timestamp)) return "";
  return new Date(timestamp).toLocaleString("en-GB", { day: "2-digit", month: "short", hour: "2-digit", minute: "2-digit" });
}

function displayCwd(cwd: string): string {
  const home = process.env.HOME;
  const fromHome = home ? relative(home, cwd) : "";
  return fromHome && !fromHome.startsWith("..") ? `~/${fromHome}` : cwd;
}

function dedupe(prompts: Prompt[]): Prompt[] {
  const seen = new Set<string>();
  return prompts.filter((prompt) => !seen.has(prompt.text) && seen.add(prompt.text));
}

/** User prompts in `entries`, newest first. */
function userPrompts(entries: Iterable<{ type: string; timestamp: string; message?: unknown }>): Prompt[] {
  const prompts: Prompt[] = [];
  for (const entry of entries) {
    if (entry.type !== "message") continue;
    const message = entry.message as { role?: string; content?: unknown };
    if (message.role !== "user") continue;
    const text = extractText(message.content);
    if (text) prompts.push({ text, timestamp: Date.parse(entry.timestamp) });
  }
  return prompts.reverse();
}

function branchPrompts(ctx: ExtensionContext): Prompt[] {
  return userPrompts(ctx.sessionManager.getBranch());
}

async function loadPrompts(cwd: string): Promise<Prompt[]> {
  try {
    const sessions = (await SessionManager.list(cwd)).sort((a, b) => b.modified.getTime() - a.modified.getTime());
    const prompts: Prompt[] = [];
    for (const session of sessions) {
      if (prompts.length >= MAX_PROMPTS) break;
      try {
        prompts.push(...userPrompts(SessionManager.open(session.path).getEntries()));
      } catch { }
    }
    return dedupe(prompts).slice(0, MAX_PROMPTS);
  } catch {
    return [];
  }
}

function extractText(content: unknown): string {
  if (typeof content === "string") return content.trim();
  if (!Array.isArray(content)) return "";
  return content
    .filter((part) => part?.type === "text" && typeof part.text === "string")
    .map((part) => part.text.trim())
    .filter(Boolean)
    .join("\n");
}
