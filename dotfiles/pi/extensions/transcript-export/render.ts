import { homedir } from "node:os";
import { escapeHtml, markdownToHtml } from "./markdown.js";
import { STYLE } from "./style.js";

type Json = any;

interface Image {
  mimeType: string;
  data: string;
}

interface Tool {
  name: string;
  args: Record<string, unknown>;
  result?: string;
  isError: boolean;
  ms?: number;
  images: Image[];
}

export type Part =
  | { kind: "text"; text: string }
  | { kind: "thinking"; text: string }
  | { kind: "tool"; tool: Tool }
  | { kind: "image"; image: Image };

export interface Turn {
  role: "user" | "assistant" | "summary";
  time?: Date;
  parts: Part[];
}

export interface SessionInfo {
  title: string;
  cwd: string;
  id: string;
  model?: string;
  started?: Date;
  updated?: Date;
  prompts: number;
}

const IMAGE_TYPES = new Set(["image/png", "image/jpeg", "image/gif", "image/webp"]);
const MAX_LINES = 120;
const MAX_CHARS = 24_000;

const isBlank = (s: string) => !s.trim();
const isObject = (v: unknown): v is Record<string, unknown> => typeof v === "object" && v !== null && !Array.isArray(v);
const dateOf = (v: unknown) => (typeof v === "string" || typeof v === "number" ? new Date(v) : undefined);
export const oneLine = (s: string, limit = 200) => s.split(/\r?\n/).join(" ").slice(0, limit).trim();

function imageOf(part: Json): Image | undefined {
  const { mimeType, data } = part ?? {};
  return IMAGE_TYPES.has(mimeType) && typeof data === "string" && /^[A-Za-z0-9+/=]*$/.test(data)
    ? { mimeType, data }
    : undefined;
}

/** Content parts in order; a tool call carries its call ID so its result can find it. */
function partsOf(content: unknown): { part: Part; callId?: string }[] {
  if (typeof content === "string") return isBlank(content) ? [] : [{ part: { kind: "text", text: content } }];
  if (!Array.isArray(content)) return [];
  return content.flatMap((p: Json): { part: Part; callId?: string }[] => {
    switch (p?.type) {
      case "text":
        return typeof p.text === "string" && !isBlank(p.text) ? [{ part: { kind: "text", text: p.text } }] : [];
      case "thinking":
        return typeof p.thinking === "string" && !isBlank(p.thinking)
          ? [{ part: { kind: "thinking", text: p.thinking } }]
          : [];
      case "toolCall": {
        const tool: Tool = {
          name: p.name ?? "tool",
          args: isObject(p.arguments) ? p.arguments : {},
          isError: false,
          images: [],
        };
        return [{ part: { kind: "tool", tool }, callId: p.id }];
      }
      case "image": {
        const image = imageOf(p);
        return image ? [{ part: { kind: "image", image } }] : [];
      }
      default:
        return [];
    }
  });
}

const textOf = (content: unknown) =>
  typeof content === "string"
    ? content
    : Array.isArray(content)
      ? content.flatMap((p: Json) => (p?.type === "text" && typeof p.text === "string" ? [p.text] : [])).join("\n")
      : "";

/** The active branch grouped into turns, with tool results attached to their calls. */
export function turnsOf(entries: Json[]): Turn[] {
  const turns: Turn[] = [];
  const tools = new Map<string, Tool>();
  for (const entry of entries) {
    const time = dateOf(entry?.timestamp);
    if (entry?.type === "compaction" || entry?.type === "branch_summary") {
      if (typeof entry.summary === "string" && !isBlank(entry.summary))
        turns.push({ role: "summary", time, parts: [{ kind: "text", text: entry.summary }] });
      continue;
    }
    const message = entry?.type === "message" ? entry.message : undefined;
    switch (message?.role) {
      case "user": {
        const parts = partsOf(message.content).map((p) => p.part);
        if (parts.length) turns.push({ role: "user", time, parts });
        break;
      }
      case "assistant": {
        if (turns.at(-1)?.role !== "assistant") turns.push({ role: "assistant", time, parts: [] });
        const turn = turns.at(-1)!;
        for (const { part, callId } of partsOf(message.content)) {
          if (part.kind === "tool" && callId) tools.set(callId, part.tool);
          turn.parts.push(part);
        }
        break;
      }
      case "toolResult": {
        const tool = tools.get(message.toolCallId);
        if (!tool) break;
        tool.result = textOf(message.content);
        tool.isError = message.isError === true;
        tool.ms = typeof message.durationMs === "number" ? message.durationMs : undefined;
        tool.images = partsOf(message.content).flatMap(({ part }) => (part.kind === "image" ? [part.image] : []));
        break;
      }
    }
  }
  return turns.filter((t) => t.parts.length > 0);
}

export function infoOf(header: Json, entries: Json[], name: string | undefined, turns: Turn[]): SessionInfo {
  const firstPrompt = turns.find((t) => t.role === "user")?.parts.find((p) => p.kind === "text");
  const models = entries.flatMap((e: Json) =>
    e?.type === "message" && e.message?.role === "assistant" && e.message.model ? [e.message.model] : [],
  );
  return {
    title: name?.trim() || (firstPrompt?.kind === "text" ? oneLine(firstPrompt.text) : "") || "(empty)",
    cwd: header?.cwd ?? "",
    id: header?.id ?? "",
    model: models.at(-1),
    started: dateOf(header?.timestamp),
    updated: dateOf(entries.at(-1)?.timestamp),
    prompts: turns.filter((t) => t.role === "user").length,
  };
}

export function headline(tool: Tool): string {
  for (const key of ["command", "path", "file_path", "pattern", "query", "url", "description", "name"]) {
    const value = tool.args[key];
    if (typeof value === "string" && !isBlank(value)) return oneLine(value, 160);
  }
  return Object.keys(tool.args).length ? oneLine(json(tool.args, false), 160) : "";
}

/** The full input, or undefined when the headline already shows all of it. */
export function inputOf(tool: Tool): { language: string; text: string } | undefined {
  const { command } = tool.args;
  if (typeof command === "string")
    return command.includes("\n") || command.length > 160 ? { language: "sh", text: command } : undefined;
  const values = Object.values(tool.args);
  if (values.length === 0) return undefined;
  if (values.length === 1 && typeof values[0] === "string" && !values[0].includes("\n") && values[0].length <= 160)
    return undefined;
  return { language: "json", text: json(tool.args, true) };
}

function json(value: unknown, pretty: boolean): string {
  const sorted = (v: unknown): unknown =>
    Array.isArray(v)
      ? v.map(sorted)
      : v && typeof v === "object"
        ? Object.fromEntries(
            Object.entries(v)
              .sort(([a], [b]) => (a < b ? -1 : 1))
              .map(([k, x]) => [k, sorted(x)]),
          )
        : v;
  return JSON.stringify(sorted(value), null, pretty ? 2 : undefined) ?? "";
}

export function duration(tool: Tool): string | undefined {
  if (tool.ms === undefined || tool.ms < 1) return undefined;
  return tool.ms < 1000 ? `${Math.round(tool.ms)} ms` : `${(tool.ms / 1000).toFixed(1)} s`;
}

/** The text cut to MAX_LINES lines and MAX_CHARS characters, with a note saying what was cut. */
export function clip(text: string): { text: string; note?: string } {
  const trimmed = text.trimEnd();
  const lines = trimmed.split("\n");
  let out = lines.length > MAX_LINES ? lines.slice(0, MAX_LINES).join("\n") : trimmed;
  let note = lines.length > MAX_LINES ? `${lines.length - MAX_LINES} more lines` : undefined;
  if (out.length > MAX_CHARS) {
    out = out.slice(0, MAX_CHARS);
    note = `cut at ${MAX_CHARS.toLocaleString("en-US")} of ${trimmed.length.toLocaleString("en-US")} characters`;
  }
  return { text: out, note };
}

type Segment = { kind: "part"; part: Part } | { kind: "activity"; parts: Part[] };

/** Consecutive thinking and tool calls fold together. */
export function segments(parts: Part[]): Segment[] {
  const out: Segment[] = [];
  let run: Part[] = [];
  const flush = () => {
    if (run.length === 1) out.push({ kind: "part", part: run[0] });
    else if (run.length > 1) out.push({ kind: "activity", parts: run });
    run = [];
  };
  for (const part of parts) {
    if (part.kind === "thinking" || part.kind === "tool") run.push(part);
    else {
      flush();
      out.push({ kind: "part", part });
    }
  }
  flush();
  return out;
}

/** "14 steps", then tool names by use and the thought count, e.g. ["14 steps", "bash ×9", "read ×3", "2 thoughts"]. */
export function activityLabel(parts: Part[]): string[] {
  const counts = new Map<string, number>();
  let thoughts = 0;
  let failed = 0;
  for (const part of parts) {
    if (part.kind === "tool") {
      counts.set(part.tool.name, (counts.get(part.tool.name) ?? 0) + 1);
      if (part.tool.isError) failed++;
    } else if (part.kind === "thinking") thoughts++;
  }
  // Map keeps first-use order and sort is stable, so ties stay in that order.
  const ranked = [...counts].sort((a, b) => b[1] - a[1]);
  const label = [`${parts.length} steps`, ...ranked.slice(0, 4).map(([name, n]) => (n > 1 ? `${name} ×${n}` : name))];
  if (ranked.length > 4) label.push(`+${ranked.length - 4} more`);
  if (thoughts) label.push(thoughts === 1 ? "1 thought" : `${thoughts} thoughts`);
  if (failed) label.push(`${failed} failed`);
  return label;
}

function metadata(info: SessionInfo): { label: string; value: string; code: boolean }[] {
  const home = homedir();
  const cwd = info.cwd === home || info.cwd.startsWith(`${home}/`) ? `~${info.cwd.slice(home.length)}` : info.cwd;
  const rows = [{ label: "Directory", value: cwd, code: true }];
  if (info.model) rows.push({ label: "Model", value: info.model, code: false });
  if (info.started) rows.push({ label: "Started", value: stamp(info.started), code: false });
  if (info.updated) rows.push({ label: "Updated", value: stamp(info.updated), code: false });
  rows.push({ label: "Prompts", value: String(info.prompts), code: false });
  rows.push({ label: "Session", value: info.id, code: true });
  return rows;
}

const stamp = (d: Date) => d.toLocaleString(undefined, { dateStyle: "medium", timeStyle: "short" });
const clock = (d: Date) => d.toLocaleTimeString(undefined, { hour: "numeric", minute: "2-digit" });

export function toMarkdown(info: SessionInfo, turns: Turn[]): string {
  const meta = metadata(info)
    .map((m) => `${m.label}: ${m.code ? `\`${m.value}\`` : m.value}`)
    .join(" · ");
  const out = [`# ${info.title}`, meta];
  for (const turn of turns) {
    out.push("---");
    if (turn.role === "summary") {
      out.push(details("Earlier context, summarized", turn.parts.map(partMarkdown).join("\n\n")));
      continue;
    }
    out.push(turn.role === "user" ? `## You${turn.time ? ` · ${clock(turn.time)}` : ""}` : "## Assistant");
    for (const segment of segments(turn.parts)) {
      out.push(
        segment.kind === "part"
          ? partMarkdown(segment.part)
          : details(
              activityLabel(segment.parts).map(escapeHtml).join(" · "),
              segment.parts.map(partMarkdown).join("\n\n"),
            ),
      );
    }
  }
  return `${out.join("\n\n")}\n`;
}

function partMarkdown(part: Part): string {
  switch (part.kind) {
    case "text":
      return part.text.trim();
    case "thinking":
      return details("Thinking", part.text.trim());
    case "image":
      return "_(image)_";
    case "tool": {
      const { tool } = part;
      const notes = [duration(tool), tool.isError ? "failed" : undefined].filter(Boolean);
      const label = [`<code>${escapeHtml(tool.name)}</code> ${escapeHtml(headline(tool))}`, ...notes].join(" · ");
      const body: string[] = [];
      const input = inputOf(tool);
      if (input) body.push(fence(clip(input.text).text, input.language));
      if (tool.result === undefined) body.push("_No result recorded._");
      else {
        const c = clip(tool.result);
        if (c.text) body.push(fence(c.text, "text"));
        if (c.note) body.push(`_… ${c.note}_`);
      }
      if (tool.images.length) body.push(`_(${tool.images.length} image${tool.images.length === 1 ? "" : "s"})_`);
      return details(label, body.join("\n\n"));
    }
  }
}

const details = (summary: string, body: string) => `<details>\n<summary>${summary}</summary>\n\n${body}\n\n</details>`;

/** A fenced code block whose fence is longer than any backtick run inside `code`. */
export function fence(code: string, language: string): string {
  const longest = Math.max(0, ...(code.match(/`+/g) ?? []).map((run) => run.length));
  const f = "`".repeat(Math.max(3, longest + 1));
  return `${f}${language}\n${code}\n${f}`;
}

export function toHtml(info: SessionInfo, turns: Turn[]): string {
  const prompts: { id: string; text: string }[] = [];
  let body = "";
  for (const turn of turns) {
    if (turn.role === "summary") {
      body += `<details class="summary"><summary>Earlier context, summarized</summary><div class="body">${turn.parts.map(partHtml).join("")}</div></details>\n`;
      continue;
    }
    if (turn.role === "user") {
      const id = `p${prompts.length + 1}`;
      const first = turn.parts.find((p) => p.kind === "text");
      prompts.push({ id, text: first?.kind === "text" ? oneLine(first.text, 120) : "(image)" });
      body += `<section class="turn user" id="${id}"><h2 class="who">You`;
      if (turn.time) body += `<time datetime="${turn.time.toISOString()}">${escapeHtml(clock(turn.time))}</time>`;
      body += "</h2>";
      body += turn.parts
        .map((p) => (p.kind === "text" ? `<div class="prompt">${escapeHtml(p.text.trim())}</div>` : partHtml(p)))
        .join("");
    } else {
      body += `<section class="turn assistant"><h2 class="who">Assistant</h2>`;
      for (const segment of segments(turn.parts)) {
        if (segment.kind === "part") body += partHtml(segment.part);
        else {
          const [count, ...detail] = activityLabel(segment.parts);
          body += `<details class="activity"><summary><span class="activity-count">${escapeHtml(count)}</span>`;
          body += `<span class="activity-detail">${detail.map(escapeHtml).join(" · ")}</span></summary>`;
          body += `<div class="steps">${segment.parts.map(partHtml).join("")}</div></details>`;
        }
      }
    }
    body += "</section>\n";
  }

  const meta = metadata(info)
    .map(
      (m) =>
        `<div><dt>${m.label}</dt><dd>${m.code ? `<code>${escapeHtml(m.value)}</code>` : escapeHtml(m.value)}</dd></div>`,
    )
    .join("");
  const toc =
    prompts.length < 2
      ? ""
      : `<nav class="toc" aria-label="Prompts"><h2>Prompts</h2><ol>${prompts.map((p) => `<li><a href="#${p.id}">${escapeHtml(p.text)}</a></li>`).join("")}</ol></nav>`;
  const title = escapeHtml(info.title);
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light dark">
<title>${title}</title>
<style>${STYLE}</style>
</head>
<body>
<div class="page">
${toc}
<main>
<header class="masthead">
<p class="kicker">pi session</p>
<h1>${title}</h1>
<dl class="meta">${meta}</dl>
</header>
${body}
<footer>Exported from pi on ${escapeHtml(stamp(new Date()))}</footer>
</main>
</div>
</body>
</html>
`;
}

function partHtml(part: Part): string {
  switch (part.kind) {
    case "text":
      return `<div class="body">${markdownToHtml(part.text)}</div>`;
    case "thinking":
      return `<details class="thinking"><summary>Thinking</summary><div class="thought">${markdownToHtml(part.text)}</div></details>`;
    case "image":
      return imageHtml(part.image);
    case "tool": {
      const { tool } = part;
      let out = `<details class="tool${tool.isError ? " error" : ""}"><summary><span class="tool-name">${escapeHtml(tool.name)}</span>`;
      out += `<span class="tool-arg">${escapeHtml(headline(tool))}</span>`;
      const meta = [
        duration(tool),
        tool.isError ? "failed" : undefined,
        tool.result === undefined ? "no result" : undefined,
      ].filter(Boolean);
      if (meta.length) out += `<span class="tool-meta">${meta.join(" · ")}</span>`;
      out += `</summary><div class="tool-body">`;
      const input = inputOf(tool);
      if (input) out += pre(clip(input.text).text, "tool-input");
      if (tool.result !== undefined) {
        const c = clip(tool.result);
        if (c.text) out += pre(c.text, "tool-output");
        if (c.note) out += `<p class="clip">… ${escapeHtml(c.note)}</p>`;
      }
      out += tool.images.map(imageHtml).join("");
      return `${out}</div></details>`;
    }
  }
}

const pre = (code: string, cls: string) => `<pre class="${cls}"><code>${escapeHtml(code)}</code></pre>`;
const imageHtml = (image: Image) =>
  `<img class="shot" alt="" loading="lazy" src="data:${image.mimeType};base64,${image.data}">`;
