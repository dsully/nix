import { AssistantMessageComponent, type ExtensionAPI, type ExtensionContext } from "@earendil-works/pi-coding-agent";
import { type Component, Container, truncateToWidth } from "@earendil-works/pi-tui";
import { patchMethod } from "../lib/patch.js";
import { textOf } from "../lib/text.js";
import { callLabel, EDIT_TOOLS, glyphOf, OWN_TOOLS, shortPath } from "./call.js";
import { codeRender } from "./code-render.js";
import { type DiffLine, markWords, parseUnified, patchPath, trimContext } from "./diff.js";
import {
  collapseThinking,
  type Part,
  silentParts,
  type ThinkingBlock,
  thinkingLine,
  thinkingLive,
  thoughtLabel,
  withoutThinking,
} from "./label.js";
import { nestedResultLines } from "./nested.js";
import { answeredQuestions, askedQuestions } from "./question.js";
import {
  diffLines,
  empty,
  framed,
  glyphLine,
  glyphMark,
  lines,
  type Status,
  tailLine,
  type Theme,
  theirs,
} from "./rows.js";
import { lookKind, type Run, Runs, runSummary } from "./runs.js";
import { type Turn, Turns } from "./turns.js";
import { usesPiFallback } from "./subagent.js";
import { formatDuration, resultTail } from "./tail.js";

const SILENT_SHORTCUT = "ctrl+'";
const DIFF_PREVIEW = 12;
const RUN_GLYPH = "●";
const TRACKED = Symbol("pi-display.tracked");

type Ctx = {
  args?: any;
  toolCallId: string;
  invalidate: () => void;
  lastComponent?: unknown;
  cwd: string;
  executionStarted: boolean;
  isPartial: boolean;
  expanded: boolean;
  isError: boolean;
  durationMs?: number;
  keyHint?: (id: string, description: string) => string;
};
type Result = { content?: unknown; details?: any };
type Options = { expanded: boolean; isPartial: boolean };
type Renderers = {
  renderShell?: "self" | "default";
  renderCall?: (args: any, theme: Theme, ctx: Ctx) => Component;
  renderResult?: (result: Result, options: Options, theme: Theme, ctx: Ctx) => Component;
};
type Planner = {
  hiddenThinkingLabel?: string;
  hideThinkingBlock?: boolean;
  isStreaming?: boolean;
  // A string key, so Pi's compacted copies keep it: they copy own string-keyed fields.
  piTranscriptThinking?: { startedAt: number; endedAt?: number };
  lastMessage?: Message;
  invalidate(): void;
};
type Message = {
  role?: string;
  timestamp?: number;
  content?: Array<{ type?: string; text?: string; thinking?: string; id?: string; name?: string; arguments?: unknown }>;
  isError?: boolean;
  toolCallId?: string;
};

export default function display(pi: ExtensionAPI) {
  const runs = new Runs();
  const rows = new Map<string, () => void>();
  const running = new Map<string, number>();
  const assistants = new Set<WeakRef<Planner>>();
  const turns = new Turns();
  const planners = new Map<number, WeakRef<Planner>>();
  let live = false;
  let ready = false;
  let silent = false;
  let ticker: ReturnType<typeof setInterval> | undefined;

  const refresh = (id: string | undefined) => (id ? rows.get(id)?.() : undefined);
  const refreshRun = (run: Run | undefined) => refresh(run?.members[0]?.id);
  const elapsed = (id: string) => (running.has(id) ? Date.now() - running.get(id)! : undefined);

  const tick = () => {
    if (running.size && !ticker) {
      ticker = setInterval(() => {
        for (const id of running.keys()) {
          refresh(id);
          refreshRun(runs.get(id));
        }
      }, 1000);
    } else if (!running.size && ticker) {
      clearInterval(ticker);
      ticker = undefined;
    }
  };

  const status = (ctx: Ctx): Status =>
    ctx.isError ? "failed" : !ctx.isPartial ? "done" : ctx.executionStarted ? "running" : live ? "streaming" : "done";

  const unframed = (ctx: Ctx): Ctx => ({ ...ctx, lastComponent: theirs(ctx.lastComponent) });

  /** "lead" draws a run's summary, "hidden" draws nothing; undefined draws the row on its own. */
  const fold = (toolName: string, args: unknown, ctx: Ctx): "lead" | "hidden" | undefined => {
    if (ctx.expanded || !lookKind(toolName, args)) return undefined;
    const run = runs.get(ctx.toolCallId);
    // A live call waits for tool_execution_start to place it, so it never flashes as its own row first.
    if (!run) return ctx.isPartial && (live || !ready) ? "hidden" : undefined;
    if (run.members.length < 2) return undefined;
    return run.members[0]!.id === ctx.toolCallId ? "lead" : "hidden";
  };

  const runRow = (run: Run, theme: Theme): Component =>
    lines((width) => {
      const failed = run.members.filter((m) => m.error).length;
      const note = failed ? theme.fg("error", ` · ${failed} failed`) : "";
      const active = [...run.members].reverse().find((m) => !m.done);
      if (!active)
        return [glyphLine(theme, RUN_GLYPH, failed ? "failed" : "done", runSummary(run.members, false), width, note)];
      const time = theme.fg("dim", ` · ${formatDuration(Date.now() - run.startedAt)}`);
      return [
        glyphLine(theme, RUN_GLYPH, "running", `${runSummary(run.members, true)}…`, width, time + note),
        tailLine(theme, { text: active.label, tone: "dim" }, width),
      ];
    });

  const diffOf = (toolName: string, args: any, details: any): { diff: DiffLine[]; path?: string } | undefined => {
    if (toolName === "write" && typeof args?.content === "string") {
      const diff = args.content
        .replace(/\n$/, "")
        .split("\n")
        .map((text: string, i: number) => ({ kind: "add" as const, line: i + 1, text: text.replace(/\t/g, "   ") }));
      return { diff, path: args.path };
    }
    const patch = details?.patch;
    if (!EDIT_TOOLS.has(toolName) || typeof patch !== "string") return undefined;
    return { diff: markWords(parseUnified(patch)), path: args?.path ?? patchPath(patch) };
  };

  const diffBlock = (toolName: string, ctx: Ctx, details: any, theme: Theme, width: number): string[] => {
    const found = ctx.isError ? undefined : diffOf(toolName, ctx.args, details);
    if (!found?.diff.length) return [];
    const shown = ctx.expanded ? found.diff : trimContext(found.diff, 1);
    const cut = ctx.expanded ? shown : shown.slice(0, DIFF_PREVIEW);
    const out = diffLines(theme, cut, found.path, width);
    const more = shown.length - cut.length;
    const hint = ctx.keyHint ? ` (${ctx.keyHint("app.tools.expand", "to expand")})` : "";
    if (more > 0) out.push(theme.fg("dim", `    … +${more} lines${hint}`));
    return out;
  };

  const rowLabel = (toolName: string, ctx: Ctx, details: any): string => {
    if (EDIT_TOOLS.has(toolName) && !ctx.args?.path && typeof details?.patch === "string") {
      return shortPath(patchPath(details.patch) ?? toolName, ctx.cwd);
    }
    return callLabel(toolName, ctx.args, ctx.cwd);
  };

  const header = (toolName: string, theme: Theme, ctx: Ctx, details?: any) => (width: number) =>
    glyphLine(theme, glyphOf(toolName), status(ctx), rowLabel(toolName, ctx, details), width);

  const plainBody = (result: Result, theme: Theme): Component => {
    const text = textOf(result.content);
    return lines((width) =>
      text
        ? text
            .split("\n")
            .slice(0, 200)
            .map((line) => truncateToWidth(`  ${theme.fg("toolOutput", line)}`, width))
        : [],
    );
  };

  /** Rows drawn here: the call while it runs; once settled, the result draws the header, its ⎿ line and any diff. */
  const ownTool = (toolName: string, own: Renderers | undefined): Renderers => {
    const writes = EDIT_TOOLS.has(toolName) || toolName === "write";
    return {
      renderShell: "self",
      renderCall(args, theme, ctx) {
        rows.set(ctx.toolCallId, ctx.invalidate);
        if (silent) return empty();
        const folded = fold(toolName, args, ctx);
        if (folded === "hidden") return empty();
        if (folded === "lead") return runRow(runs.get(ctx.toolCallId)!, theme);
        if (ctx.expanded && !writes && own?.renderCall) return framed(own.renderCall(args, theme, unframed(ctx)), "  ");
        if (!ctx.isPartial && !(ctx.expanded && !writes)) return empty();
        return lines((width) => [header(toolName, theme, ctx)(width)]);
      },
      renderResult(result, options, theme, ctx) {
        if (silent || fold(toolName, ctx.args, ctx)) return empty();
        if (ctx.expanded && !writes)
          return own?.renderResult
            ? framed(own.renderResult(result, options, theme, unframed(ctx)), "  ")
            : plainBody(result, theme);
        const tail = resultTail({
          toolName,
          args: ctx.args,
          text: textOf(result.content),
          details: result.details,
          isError: ctx.isError,
          isPartial: options.isPartial,
          durationMs: ctx.durationMs,
          elapsedMs: elapsed(ctx.toolCallId),
        });
        if (options.isPartial) return lines((width) => [tailLine(theme, tail, width)]);
        return lines((width) => [
          header(toolName, theme, ctx, result.details)(width),
          tailLine(theme, tail, width),
          ...diffBlock(toolName, ctx, result.details, theme, width),
        ]);
      },
    };
  };

  /** Tools with their own look keep it, without Pi's box, under a status glyph. */
  const customTool = (toolName: string, own: Renderers): Renderers => ({
    renderShell: "self",
    renderCall(args, theme, ctx) {
      rows.set(ctx.toolCallId, ctx.invalidate);
      if (silent) return empty();
      const mark = glyphMark(theme, glyphOf(toolName), status(ctx));
      if (own.renderCall) return framed(own.renderCall(args, theme, unframed(ctx)), mark);
      return lines((width) => [
        glyphLine(theme, glyphOf(toolName), status(ctx), callLabel(toolName, args, ctx.cwd), width),
      ]);
    },
    renderResult(result, options, theme, ctx) {
      if (silent) return empty();
      if (usesPiFallback(toolName, ctx.args)) {
        const nested = nestedResultLines(textOf(result.content), options.expanded);
        return lines((width) => nested.map((line) => truncateToWidth(`  ${theme.fg("dim", line)}`, width)));
      }
      if (own.renderResult) return framed(own.renderResult(result, options, theme, unframed(ctx)), "  ");
      if (options.expanded) return plainBody(result, theme);
      const tail = resultTail({
        toolName,
        text: textOf(result.content),
        isError: ctx.isError,
        isPartial: options.isPartial,
        durationMs: ctx.durationMs,
      });
      return lines((width) => [tailLine(theme, tail, width)]);
    },
  });

  /** Tools that draw their own shell, like bg_run, keep everything but silent mode. */
  const quietTool = (own: Renderers): Renderers => ({
    renderShell: "self",
    renderCall(args, theme, ctx) {
      rows.set(ctx.toolCallId, ctx.invalidate);
      return silent || !own.renderCall ? empty() : own.renderCall(args, theme, unframed(ctx));
    },
    renderResult(result, options, theme, ctx) {
      return silent || !own.renderResult ? empty() : own.renderResult(result, options, theme, unframed(ctx));
    },
  });

  /** An asked question reads as the question and the user's answer, not as a tool call. */
  const questionTool = (own: Renderers | undefined): Renderers => {
    const fallback = ownTool("ask_user_question", own);
    return {
      renderShell: "self",
      renderCall(args, theme, ctx) {
        rows.set(ctx.toolCallId, ctx.invalidate);
        if (silent || !ctx.isPartial) return empty();
        const asked = askedQuestions(args);
        const more = asked.length > 1 ? theme.fg("dim", ` (+${asked.length - 1} more)`) : "";
        return lines((width) => [glyphLine(theme, "?", status(ctx), asked[0] ?? "ask_user_question", width, more)]);
      },
      renderResult(result, options, theme, ctx) {
        if (silent) return empty();
        if (options.isPartial)
          return lines((width) => [tailLine(theme, { text: "awaiting your answer…", tone: "warning" }, width)]);
        const answered = answeredQuestions(result.details);
        if (answered === "declined") {
          const first = askedQuestions(ctx.args)[0] ?? "Questions";
          return lines((width) => [
            glyphLine(theme, "?", "done", first, width),
            tailLine(theme, { text: "User declined to answer", tone: "warning" }, width),
          ]);
        }
        if (!answered) return fallback.renderResult!(result, options, theme, ctx);
        return lines((width) =>
          answered.flatMap(({ question, answer }) => [
            glyphLine(theme, "?", "done", theme.italic(question), width),
            tailLine(theme, { text: answer ?? "(no answer)", tone: answer ? "text" : "dim" }, width),
          ]),
        );
      },
    };
  };

  pi.registerToolRenderer((toolName, next) => {
    const own = next() as Renderers | undefined;
    if (toolName === "ask_user_question") return questionTool(own) as never;
    if (OWN_TOOLS.has(toolName)) return ownTool(toolName, own) as never;
    if (own?.renderShell === "self") return quietTool(own) as never;
    if (!own?.renderCall && !own?.renderResult) return ownTool(toolName, undefined) as never;
    return customTool(toolName, own) as never;
  });

  const track = (planner: Planner) => {
    const tagged = planner as Planner & { [TRACKED]?: true };
    if (tagged[TRACKED]) return;
    tagged[TRACKED] = true;
    assistants.add(new WeakRef(planner));
  };

  /** Later rounds feed the turn's one thought line, which the first round that thought draws. */
  const refreshHead = (turn: Turn, label: string) => {
    if (turn.shown === label) return;
    turn.shown = label;
    const head = planners.get(turn.head()!)?.deref();
    if (head) queueMicrotask(() => head.invalidate());
  };

  patchMethod<(this: Planner, message: Message) => Part[]>(
    AssistantMessageComponent.prototype,
    "planContent",
    "pi-display.planContent",
    (original) =>
      original &&
      function (this: Planner, message: Message) {
        track(this);
        const key = message?.timestamp;
        if (typeof key === "number") planners.set(key, new WeakRef(this));
        let parts = collapseThinking(original.call(this, message));
        const content = message?.content as ThinkingBlock[] | undefined;
        if (content?.some((block) => block.type === "thinking")) {
          const now = Date.now();
          if (!this.piTranscriptThinking && this.isStreaming) this.piTranscriptThinking = { startedAt: now };
          const timing = this.piTranscriptThinking;
          const isLive = thinkingLive(content, this.isStreaming === true);
          if (timing && !isLive) timing.endedAt ??= now;
          const spent = timing ? (timing.endedAt ?? now) - timing.startedAt : undefined;
          // Recorded even while thinking is shown, so hiding it later still finds one line per turn.
          const turn = typeof key === "number" ? (this.isStreaming ? turns.assign(key) : turns.get(key)) : undefined;
          turn?.set(key!, { line: thinkingLine(content), ms: spent, live: isLive });
          if (this.hideThinkingBlock && this.hiddenThinkingLabel?.trim()) {
            if (!turn) {
              this.hiddenThinkingLabel = thoughtLabel(thinkingLine(content), isLive, spent);
            } else {
              const { line, live: turnLive, ms, count } = turn.summary();
              const label = thoughtLabel(line, turnLive, ms, count);
              if (turn.head() === key) {
                turn.shown = label;
                this.hiddenThinkingLabel = label;
              } else {
                refreshHead(turn, label);
                parts = withoutThinking(parts);
              }
            }
          }
        }
        return silent ? silentParts(parts) : parts;
      },
  );

  // Pi swaps settled messages for compacted copies, which silent mode must still reach.
  patchMethod<(this: Planner) => Planner>(
    AssistantMessageComponent.prototype,
    "compactedCopy",
    "pi-display.compactedCopy",
    (original) =>
      original &&
      function (this: Planner) {
        const copy = original.call(this);
        track(copy);
        const key = copy.lastMessage?.timestamp;
        if (typeof key === "number") planners.set(key, new WeakRef(copy));
        return copy;
      },
  );

  const redraw = (ctx: ExtensionContext) => {
    if (!ctx.hasUI) return;
    ctx.ui.setWidget("pi-display-redraw", (tui) => {
      setTimeout(() => {
        ctx.ui.setWidget("pi-display-redraw", undefined);
        tui.requestRender(true);
      }, 0);
      return new Container();
    });
  };

  const replanAssistants = () => {
    for (const ref of assistants) {
      const assistant = ref.deref();
      if (assistant) assistant.invalidate();
      else assistants.delete(ref);
    }
  };

  const setSilent = (on: boolean, ctx: ExtensionContext) => {
    silent = on;
    for (const invalidate of rows.values()) invalidate();
    replanAssistants();
    redraw(ctx);
    if (ctx.hasUI)
      ctx.ui.notify(
        on ? `Silent mode on (${SILENT_SHORTCUT} or /silent to show tool rows)` : "Silent mode off",
        "info",
      );
  };

  pi.registerCommand("silent", {
    description: "Hide tool rows and intermediate turns: /silent [on|off]",
    handler: async (args: string, ctx: ExtensionContext) => {
      const choice = args.trim().toLowerCase();
      setSilent(choice === "on" ? true : choice === "off" ? false : !silent, ctx);
    },
  });

  pi.registerShortcut(SILENT_SHORTCUT, {
    description: "Toggle silent mode",
    handler: async (ctx: ExtensionContext) => setSilent(!silent, ctx),
  });

  /** Whether a message draws its thinking: only the first message of a turn that thought does. */
  const drawsThought = (message: Message) => {
    const key = message.timestamp;
    const turn = typeof key === "number" ? turns.get(key) : undefined;
    return !turn || turn.head() === key;
  };

  const visible = (message: Message) =>
    (message.content ?? []).some(
      (part) =>
        (part.type === "text" && part.text?.trim()) ||
        (part.type === "thinking" && part.thinking?.trim() && drawsThought(message)),
    );

  const rebuild = (ctx: ExtensionContext) => {
    runs.clear();
    turns.clear();
    const branch = ctx.sessionManager.getBranch() as Array<{ type: string; message?: Message }>;
    const failed = new Set(
      branch.flatMap((entry) =>
        entry.message?.role === "toolResult" && entry.message.isError && entry.message.toolCallId
          ? [entry.message.toolCallId]
          : [],
      ),
    );
    for (const entry of branch) {
      const message = entry.type === "message" ? entry.message : undefined;
      if (!message) continue;
      if (message.role === "user") {
        runs.end();
        turns.start();
      }
      if (message.role !== "assistant") continue;
      const thinking = message.content as ThinkingBlock[] | undefined;
      if (typeof message.timestamp === "number" && thinking?.some((block) => block.type === "thinking")) {
        turns.assign(message.timestamp).set(message.timestamp, { line: thinkingLine(thinking), live: false });
      }
      if (visible(message)) runs.end();
      for (const part of message.content ?? []) {
        if (part.type !== "toolCall" || !part.id || !part.name) continue;
        const kind = lookKind(part.name, part.arguments);
        if (!kind) runs.end();
        else
          runs.add(
            {
              id: part.id,
              kind,
              label: callLabel(part.name, part.arguments as never, ctx.cwd),
              done: true,
              error: failed.has(part.id),
            },
            0,
          );
      }
    }
    runs.end();
  };

  pi.on("session_start", async (_event, ctx) => {
    running.clear();
    tick();
    planners.clear();
    rebuild(ctx);
    ready = true;
    for (const invalidate of rows.values()) invalidate();
    replanAssistants();
    redraw(ctx);
  });

  pi.on("agent_start", async () => {
    live = true;
    runs.end();
    turns.start();
  });

  pi.on("agent_end", async () => {
    live = false;
    runs.end();
  });

  pi.on("message_end", async (event) => {
    const message = event.message as Message;
    if (message.role === "user") turns.start();
    if (message.role === "assistant" && visible(message)) runs.end();
  });

  pi.on("tool_execution_start", async (event, ctx) => {
    if ((event as { parentToolCallId?: string }).parentToolCallId) return;
    running.set(event.toolCallId, Date.now());
    tick();
    const kind = lookKind(event.toolName, event.args);
    if (!kind) {
      runs.end();
      return;
    }
    const run = runs.add(
      { id: event.toolCallId, kind, label: callLabel(event.toolName, event.args, ctx.cwd) },
      Date.now(),
    );
    refreshRun(run);
    refresh(event.toolCallId);
  });

  pi.on("tool_execution_end", async (event) => {
    if ((event as { parentToolCallId?: string }).parentToolCallId) return;
    running.delete(event.toolCallId);
    tick();
    refreshRun(runs.finish(event.toolCallId, event.isError));
  });

  pi.on("session_shutdown", async () => {
    running.clear();
    tick();
  });

  codeRender(pi);
}
