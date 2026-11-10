import { codemodeCallsSummary } from "./codemode.js";

export type Tone = "muted" | "dim" | "error" | "warning" | "text";

/** The `⎿` line of a row: `text` may be cut to fit, `suffix` (a duration) always stays. */
export type Tail = { text: string; tone: Tone; suffix?: string };

export type TailInput = {
  toolName: string;
  args?: Record<string, unknown>;
  text: string;
  details?: unknown;
  isError: boolean;
  isPartial: boolean;
  durationMs?: number;
  elapsedMs?: number;
};

export function plural(count: number, one: string, many = `${one}s`): string {
  return `${count} ${count === 1 ? one : many}`;
}

export function formatDuration(ms: number): string {
  const seconds = ms / 1000;
  if (seconds < 10) return `${seconds.toFixed(1)}s`;
  if (seconds < 60) return `${Math.round(seconds)}s`;
  const minutes = Math.floor(seconds / 60);
  return `${minutes}m ${String(Math.round(seconds % 60)).padStart(2, "0")}s`;
}

function lines(text: string): string[] {
  return text.split("\n").filter((line) => line.trim());
}

function record(value: unknown): Record<string, unknown> | undefined {
  return typeof value === "object" && value !== null && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : undefined;
}

function metrics(details: unknown): Record<string, unknown> | undefined {
  return record(record(details)?.metrics);
}

function num(value: unknown): number | undefined {
  return typeof value === "number" && Number.isFinite(value) ? value : undefined;
}

/** `+added/-removed` for an edit, from hashline metrics or a counted unified diff. */
export function editStat(details: unknown): string | undefined {
  const m = metrics(details);
  let added = num(m?.added_lines);
  let removed = num(m?.removed_lines);
  if (added === undefined || removed === undefined) {
    const diff = record(details)?.patch ?? record(details)?.diff;
    if (typeof diff !== "string") return undefined;
    added = removed = 0;
    for (const line of diff.split("\n")) {
      if (/^\+(?!\+\+ )/.test(line)) added++;
      else if (/^-(?!-- )/.test(line)) removed++;
    }
  }
  return added + removed === 0 ? "no changes" : `+${added}/-${removed}`;
}

function settledText(input: TailInput): string {
  const shown = lines(input.text);
  const m = metrics(input.details);
  switch (input.toolName) {
    case "bash":
      return shown.length ? plural(shown.length, "line") : "no output";
    case "read":
      return `${plural(shown.length, "line")}${m?.truncated === true ? " (truncated)" : ""}`;
    case "grep": {
      const matches = num(m?.matches);
      const files = num(m?.files);
      if (matches === 0) return "no matches";
      if (matches !== undefined && files !== undefined)
        return `${plural(matches, "match", "matches")} in ${plural(files, "file")}`;
      return shown.length ? plural(shown.length, "line") : "no matches";
    }
    case "find":
    case "ls":
      return shown.length ? plural(shown.length, "entry", "entries") : "nothing found";
    case "write":
      return `+${plural(lines(String(input.args?.content ?? "")).length, "line")}`;
    case "codemode":
      return (
        codemodeCallsSummary(record(input.details)?.calls) ??
        (shown.length ? plural(shown.length, "line") : "no output")
      );
    case "edit":
    case "replace":
    case "replace_match":
    case "insert":
      return editStat(input.details) ?? (shown[0]?.trim() || "applied");
    default:
      if (shown.length === 0) return "done";
      return shown.length === 1 ? shown[0]!.trim() : `${shown[0]!.trim()} (+${plural(shown.length - 1, "line")})`;
  }
}

/** A failed command's exit code and its last output line; other tools fail with their first line. */
function errorText(toolName: string, text: string): string {
  const shown = lines(text)
    .map((line) => line.trim())
    .filter((line) => line !== "(no output)");
  const exit = shown.findLast((line) => /exited with code \d+/i.test(line));
  const code = exit?.match(/code (\d+)/i)?.[1];
  const output = shown.filter((line) => line !== exit);
  const line = toolName === "bash" ? output.at(-1) : output[0];
  if (code) return line ? `exit ${code} · ${line}` : `exit ${code}`;
  return line ?? "failed";
}

export function resultTail(input: TailInput): Tail {
  if (input.isPartial) {
    const latest = lines(input.text).at(-1)?.trim();
    const suffix = input.elapsedMs === undefined ? undefined : formatDuration(input.elapsedMs);
    return { text: latest ?? "running…", tone: latest ? "dim" : "warning", suffix };
  }
  const suffix =
    input.durationMs === undefined || input.durationMs < 1000 ? undefined : formatDuration(input.durationMs);
  if (input.isError) return { text: errorText(input.toolName, input.text), tone: "error", suffix };
  return { text: settledText(input), tone: "muted", suffix };
}
