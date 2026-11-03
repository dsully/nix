import type { Task } from "../tool/types.js";

/** Per-session reminder flags; `sent` holds further reminders back until the todo tool is used again. */
export interface ReminderState {
  due: boolean;
  sent: boolean;
}

export function newReminderState(): ReminderState {
  return { due: false, sent: false };
}

const inProgress = (tasks: readonly Task[]) => tasks.filter((t) => t.status === "in_progress");

export function noteTurnEnd(r: ReminderState, textOnly: boolean, tasks: readonly Task[]): void {
  if (textOnly && !r.sent && inProgress(tasks).length) r.due = true;
}

export function noteTodoUse(r: ReminderState): void {
  r.due = false;
  r.sent = false;
}

export function takeReminder(r: ReminderState, tasks: readonly Task[]): string | undefined {
  if (!r.due) return undefined;
  r.due = false;
  const open = inProgress(tasks);
  if (!open.length) return undefined;
  r.sent = true;
  const list = open.map((t) => `#${t.id} ${t.subject}`).join("; ");
  return `<system-reminder>\nStill in_progress: ${list}. Mark each completed with the todo tool if it is done, or set it back to pending. Do not mention this reminder to the user.\n</system-reminder>`;
}
