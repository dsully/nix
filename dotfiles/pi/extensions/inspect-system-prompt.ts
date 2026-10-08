/**
 * /inspect-system-prompt [filter] (alias /tools) - popup with the system prompt and all configured tools.
 *
 * Collapsed sections show only their header. Expand a section to see the full prompt, or a tool's description, path, prompt guidelines, and parameter schema.
 */

import type { ExtensionAPI, ExtensionCommandContext, Theme } from "@earendil-works/pi-coding-agent";
import { type Component, Key, matchesKey, type TUI, truncateToWidth, wrapTextWithAnsi } from "@earendil-works/pi-tui";

interface Section {
  header: string;
  details: string;
}

class InspectPopup implements Component {
  private selected = 0;
  private scroll = 0;
  private readonly expanded = new Set<number>();

  constructor(
    private readonly tui: TUI,
    private readonly theme: Theme,
    private readonly title: string,
    private readonly sections: Section[],
    private readonly done: () => void,
  ) { }

  handleInput(data: string): void {
    const last = this.sections.length - 1;
    if (matchesKey(data, Key.escape) || data === "q") return this.done();
    if (matchesKey(data, Key.up) || data === "k") this.selected = Math.max(0, this.selected - 1);
    else if (matchesKey(data, Key.down) || data === "j") this.selected = Math.min(last, this.selected + 1);
    else if (matchesKey(data, Key.home)) this.selected = 0;
    else if (matchesKey(data, Key.end)) this.selected = last;
    else if (matchesKey(data, Key.pageUp)) this.scroll -= this.viewHeight();
    else if (matchesKey(data, Key.pageDown)) this.scroll += this.viewHeight();
    else if (matchesKey(data, Key.enter) || matchesKey(data, Key.space)) this.toggle(this.selected);
    else if (data === "a") this.toggleAll();
    else return;
    this.tui.requestRender();
  }

  render(width: number): string[] {
    const { theme } = this;
    const inner = Math.max(10, width - 4);
    const body: string[] = [];
    let selectedTop = 0;
    let selectedBottom = 0;

    this.sections.forEach((section, i) => {
      const isSelected = i === this.selected;
      const isExpanded = this.expanded.has(i);
      if (isSelected) selectedTop = body.length;
      const arrow = isExpanded ? "▾" : "▸";
      const cursor = isSelected ? theme.fg("accent", `${arrow} `) : `${arrow} `;
      const header = isSelected ? theme.bg("selectedBg", section.header) : section.header;
      body.push(...wrapTextWithAnsi(cursor + header, inner));
      if (isExpanded) for (const line of section.details.split("\n")) body.push(...wrapTextWithAnsi(`    ${line}`, inner));
      if (isSelected) selectedBottom = body.length;
    });

    const height = this.viewHeight();
    const maxScroll = Math.max(0, body.length - height);
    if (selectedTop < this.scroll) this.scroll = selectedTop;
    if (selectedBottom > this.scroll + height) this.scroll = Math.min(selectedTop, selectedBottom - height);
    this.scroll = Math.min(Math.max(0, this.scroll), maxScroll);

    const edge = (left: string, label: string, right: string) =>
      theme.fg("border", `${left}${truncateToWidth(`─ ${label} ${"─".repeat(width)}`, width - 2, "")}${right}`);
    const side = theme.fg("border", "│");
    const position = body.length > height ? ` ${this.scroll + 1}-${Math.min(body.length, this.scroll + height)}/${body.length}` : "";
    const keys = "↑↓ move · enter expand · a all · pgup/pgdn scroll · esc close";

    return [
      edge("╭", this.title, "╮"),
      ...body.slice(this.scroll, this.scroll + height).map((line) => `${side} ${truncateToWidth(line, inner, "", true)} ${side}`),
      edge("╰", `${keys}${position}`, "╯"),
    ];
  }

  invalidate(): void { }

  private viewHeight(): number {
    return Math.max(5, Math.floor(this.tui.terminal.rows * 0.85) - 2);
  }

  private toggle(i: number): void {
    if (!this.expanded.delete(i)) this.expanded.add(i);
  }

  private toggleAll(): void {
    if (this.expanded.size === this.sections.length) this.expanded.clear();
    else this.sections.forEach((_, i) => this.expanded.add(i));
  }
}

export default function(pi: ExtensionAPI) {
  const handler = async (args: string, ctx: ExtensionCommandContext) => {
    if (!ctx.hasUI) return;
    const filter = args.trim().toLowerCase();
    const activeNames = new Set(pi.getActiveTools());
    const all = pi.getAllTools();
    const prompt = ctx.getSystemPrompt();

    const sentTools = all
      .filter((tool) => activeNames.has(tool.name))
      .map(({ name, description, parameters }) => ({ name, description, parameters }));
    const sent = `${prompt}\n${JSON.stringify(sentTools, null, 2)}`.trim();
    const words = sent ? sent.split(/\s+/).length : 0;

    const tools = all
      .filter((tool) => !filter || tool.name.toLowerCase().includes(filter))
      .sort((a, b) => Number(activeNames.has(b.name)) - Number(activeNames.has(a.name)) || a.name.localeCompare(b.name));

    await ctx.ui.custom<void>(
      (tui, theme, _keybindings, done) => {
        const label = (text: string) => theme.fg("accent", text);
        const sections: Section[] = [
          {
            header: `${theme.bold("System prompt")} ${theme.fg("muted", `${prompt.split("\n").length} lines`)}`,
            details: prompt,
          },
          ...tools.map((tool) => {
            const active = activeNames.has(tool.name);
            const guidelines = (tool.promptGuidelines ?? []).map((g) => `  - ${g}`);
            return {
              header: [
                active ? theme.fg("success", "●") : theme.fg("muted", "○"),
                active ? theme.bold(tool.name) : tool.name,
                theme.fg("muted", `(${tool.sourceInfo.source})`),
              ].join(" "),
              details: [
                (tool.description ?? "").trim(),
                `${label("path:")} ${tool.sourceInfo.path}`,
                ...(guidelines.length ? [label("guidelines:"), ...guidelines] : []),
                `${label("params:")} ${JSON.stringify(tool.parameters, null, 2)}`,
              ]
                .filter(Boolean)
                .join("\n"),
            };
          }),
        ];
        const title = `${activeNames.size} active / ${all.length} tools · sent: ${sent.split("\n").length} lines, ${words} words`;
        return new InspectPopup(tui, theme, title, sections, () => done());
      },
      { overlay: true, overlayOptions: { width: "90%", maxHeight: "85%", anchor: "center" } },
    );
  };

  const description = "Popup with the system prompt and all tools; optional arg filters tools by name";
  pi.registerCommand("inspect-system-prompt", { description, handler });
  pi.registerCommand("tools", { description, handler });
}
