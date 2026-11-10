import { formatDuration } from "./tail.js";

export type Part = { kind: string; hidden?: boolean };
export type ThinkingBlock = { type?: string; thinking?: string };

const MAX_LABEL = 100;

export function thinkingLine(content: readonly ThinkingBlock[] | undefined): string | undefined {
  for (const block of content ?? []) {
    if (block.type !== "thinking") continue;
    const line = block.thinking
      ?.split("\n")
      .map((part) => part.trim())
      .find(Boolean);
    if (!line) continue;
    return line.length > MAX_LABEL ? `${line.slice(0, MAX_LABEL - 1)}…` : line;
  }
  return undefined;
}

export function collapseThinking<T extends Part>(parts: T[]): T[] {
  let last = -1;
  for (let index = 0; index < parts.length; index++) {
    if (parts[index]?.kind === "thinking" && parts[index]?.hidden) last = index;
  }
  if (last < 0) return parts;
  const kept: T[] = [];
  for (let index = 0; index < parts.length; index++) {
    const part = parts[index];
    if (!part) continue;
    if (part.kind === "thinking" && part.hidden && index !== last) continue;
    if (part.kind === "spacer" && kept.at(-1)?.kind === "spacer") continue;
    kept.push(part);
  }
  if (kept[0]?.kind === "spacer") kept.shift();
  return kept;
}

const SPINNER = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
const SPINNER_MS = 80;

/** Thinking is live while the message streams and nothing has followed the thinking yet. */
export function thinkingLive(content: readonly ThinkingBlock[] | undefined, isStreaming: boolean): boolean {
  return isStreaming && content?.at(-1)?.type === "thinking";
}

export function thoughtLabel(
  line: string | undefined,
  live: boolean,
  elapsedMs: number | undefined,
  count = 1,
): string {
  const times = count > 1 ? ` ×${count}` : "";
  if (live) return `${SPINNER[Math.floor((elapsedMs ?? 0) / SPINNER_MS) % SPINNER.length]} Thinking…${times}`;
  const duration = elapsedMs === undefined ? "" : ` · ${formatDuration(elapsedMs)}`;
  return `* Thought${times}${line ? `: ${line}` : ""}${duration}`;
}

/** A later round of a turn: its thinking shows on the turn's first thought line, so none of it draws here. */
export function withoutThinking<T extends Part>(parts: T[]): T[] {
  const kept = parts.filter((part) => part.kind !== "thinking");
  const drawn = (part: T | undefined) => part?.kind === "text" || part?.kind === "error";
  return kept.filter((part, index) => part.kind !== "spacer" || drawn(kept[index + 1]));
}

/** Silent mode keeps only answers: a message that calls tools shows nothing, an answer loses its thinking. */
export function silentParts<T extends Part>(parts: T[]): T[] {
  const callsTools = parts.some((part) => part.kind === "toolCalls" && (part as { present?: boolean }).present);
  const kept = parts.filter((part) =>
    callsTools ? part.kind === "toolCalls" || part.kind === "error" : part.kind !== "thinking",
  );
  const out: T[] = [];
  for (const part of kept) {
    if (part.kind === "spacer" && out.at(-1)?.kind === "spacer") continue;
    out.push(part);
  }
  return out;
}
