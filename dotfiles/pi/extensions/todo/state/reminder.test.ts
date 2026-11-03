import { expect, test } from "bun:test";
import type { Task } from "../tool/types.js";
import { newReminderState, noteTodoUse, noteTurnEnd, takeReminder } from "./reminder.js";

const active: Task[] = [
  { id: 1, subject: "done", status: "completed" },
  { id: 2, subject: "wip", status: "in_progress" },
];

test("a text-only turn that leaves work in progress queues one reminder naming that task", () => {
  const r = newReminderState();
  noteTurnEnd(r, true, active);
  const text = takeReminder(r, active);
  expect(text).toContain("#2");
  expect(text).not.toContain("#1");
  expect(takeReminder(r, active)).toBeUndefined();
});

test("no reminder after a tool turn or with nothing in progress", () => {
  const r = newReminderState();
  noteTurnEnd(r, false, active);
  noteTurnEnd(r, true, [{ id: 1, subject: "x", status: "pending" }]);
  expect(takeReminder(r, active)).toBeUndefined();
});

test("after one reminder, the next fires only once the todo tool has been used", () => {
  const r = newReminderState();
  noteTurnEnd(r, true, active);
  takeReminder(r, active);
  noteTurnEnd(r, true, active);
  expect(takeReminder(r, active)).toBeUndefined();
  noteTodoUse(r);
  noteTurnEnd(r, true, active);
  expect(takeReminder(r, active)).toBeDefined();
});

test("a queued reminder is dropped when the task finished before the next request", () => {
  const r = newReminderState();
  noteTurnEnd(r, true, active);
  expect(takeReminder(r, [{ ...active[1], status: "completed" }])).toBeUndefined();
});
