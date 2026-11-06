/** Ghostty tab status sequences. Pure so it can be tested without a TTY. */

import { textOf } from "../lib/text.js";

export type StatusPhase = "idle" | "working" | "blocked" | "done" | "error";
export type BlockedKind = "permission" | "question";

export interface StatusReport {
  phase: StatusPhase;
  /** Short human text. Already sanitized by the caller is fine; this module sanitizes again. */
  detail: string;
  folder: string;
  name?: string;
  /** Spinner frame index while working. */
  frame?: number;
  kind?: BlockedKind;
}

const WAITING_TOOLS = new Set(["ask_user_question", "exit_plan_mode", "enter_plan_mode"]);

const SPINNER = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

const STATUS_EMOJI: Record<Exclude<StatusPhase, "working">, string> = {
  idle: "",
  blocked: "✋",
  done: "✅",
  error: "❌",
};

/** Tab badge. Question waits are distinct from permission waits. */
function statusEmoji(report: StatusReport): string {
  if (report.phase === "working") return SPINNER[(report.frame ?? 0) % SPINNER.length];
  if (report.phase === "blocked" && report.kind === "question") return "❓";
  return STATUS_EMOJI[report.phase];
}

/** Tab: mark and session name, or folder when unnamed. Window: the same, then the detail. */
export function titles(report: StatusReport): { tab: string; window: string } {
  const mark = statusEmoji(report);
  const folder = sanitize(report.folder, 24);
  const tab = sanitize(report.name ?? "", 24) || folder;
  const parts = [sanitize(report.name ?? "", 48) || folder];
  const detail = sanitize(report.detail, 48);
  if (detail && detail !== mark) parts.push(detail);
  const window = parts.join(" · ");
  return mark ? { tab: `${mark} ${tab}`, window: `${mark} ${window}` } : { tab, window };
}

export function activityFromTool(
  toolName: string,
  args: unknown,
): { detail: string; blocked: boolean; kind?: BlockedKind } {
  const detail = sanitize(detailFromArgs(toolName, args), 48) || toolName;
  if (WAITING_TOOLS.has(toolName)) {
    return { detail, blocked: true, kind: toolName === "ask_user_question" ? "question" : "permission" };
  }
  return { detail, blocked: false };
}

/** OSC 2 window title, OSC 1 tab title, and ConEmu OSC 9;3 tab title. Ghostty ignores OSC 1, so its tab shows OSC 2. */
export function titleSequences(report: StatusReport): string {
  const { tab, window } = titles(report);
  return [osc(2, window), osc(1, tab), report.phase === "idle" ? osc(9, "3;") : osc(9, `3;${tab}`)].join("");
}

/** OSC bytes for one report: titles and the OSC 9;4 progress mark. */
export function statusSequences(report: StatusReport): string {
  return titleSequences(report) + progressSequence(report.phase);
}

export function clearSequences(): string {
  return [osc(9, "4;0"), osc(9, "3;"), osc(0, "")].join("");
}

/** Ghostty drops OSC 9;4 unless it is repeated during long work. */
export function progressKeepalive(phase: StatusPhase): string {
  return phase === "idle" ? "" : progressSequence(phase);
}

function progressSequence(phase: StatusPhase): string {
  switch (phase) {
    case "working":
      return osc(9, "4;3");
    case "blocked":
      return osc(9, "4;4");
    case "done":
      return osc(9, "4;1;100");
    case "error":
      return osc(9, "4;2");
    default:
      return osc(9, "4;0");
  }
}

function osc(code: number, body: string): string {
  return `\x1b]${code};${body}\x07`;
}

function detailFromArgs(toolName: string, args: unknown): string {
  if (!args || typeof args !== "object") return toolName;
  const record = args as Record<string, unknown>;
  if (typeof record.command === "string") return record.command.split("\n")[0] ?? toolName;
  if (typeof record.path === "string") return record.path.split("/").pop() || record.path;
  if (typeof record.file_path === "string") return record.file_path.split("/").pop() || record.file_path;
  if (typeof record.question === "string") return record.question;
  if (Array.isArray(record.questions)) {
    const first = record.questions[0];
    if (first && typeof first === "object" && typeof (first as { question?: unknown }).question === "string") {
      return (first as { question: string }).question;
    }
  }
  if (typeof record.plan === "string") return record.plan.split("\n").find((line) => line.trim()) ?? toolName;
  return toolName;
}

export function sanitize(value: string, max: number): string {
  const flat = value
    .replace(/[\u0000-\u001f\u007f]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
  const chars = Array.from(flat);
  return chars.length > max ? `${chars.slice(0, max - 1).join("")}…` : flat;
}

export function assistantSummary(messages: unknown): string {
  if (!Array.isArray(messages)) return "";
  for (let i = messages.length - 1; i >= 0; i--) {
    const message = messages[i] as { role?: string; content?: unknown };
    if (message?.role !== "assistant") continue;
    const text = textOf(message.content, " ");
    if (text) return sanitize(text, 48);
  }
  return "";
}
