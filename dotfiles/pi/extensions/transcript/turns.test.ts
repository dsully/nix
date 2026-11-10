import { expect, test } from "bun:test";
import { thoughtLabel, withoutThinking } from "./label.js";
import { Turns } from "./turns.js";

test("messages share a turn until a user message starts the next", () => {
  const turns = new Turns();
  const first = turns.assign(1);
  expect(turns.assign(2)).toBe(first);
  turns.start();
  expect(turns.assign(3)).not.toBe(first);
  expect(turns.assign(1)).toBe(first);
});

test("the first message that thought heads the turn", () => {
  const turn = new Turns().assign(1);
  turn.set(5, { line: "a", live: false });
  turn.set(9, { line: "b", live: false });
  expect(turn.head()).toBe(5);
});

test("the summary shows the newest thought and the time across all of them", () => {
  const turn = new Turns().assign(1);
  turn.set(1, { line: "first", ms: 1000, live: false });
  turn.set(2, { line: "second", ms: 2500, live: false });
  expect(turn.summary()).toEqual({ line: "second", live: false, ms: 3500, count: 2 });
});

test("a turn is live while its newest thought runs", () => {
  const turn = new Turns().assign(1);
  turn.set(1, { line: "first", ms: 1000, live: false });
  turn.set(2, { ms: 200, live: true });
  expect(turn.summary()).toMatchObject({ line: "first", live: true });
});

test("the label counts thoughts only when there are several", () => {
  expect(thoughtLabel("x", false, undefined, 1)).not.toContain("×");
  expect(thoughtLabel("x", false, undefined, 3)).toContain("×3");
});

test("a later round draws no thinking and no spacer left behind for it", () => {
  const parts = [{ kind: "spacer" }, { kind: "thinking", hidden: true }, { kind: "toolCalls" }];
  expect(withoutThinking(parts).map((p) => p.kind)).toEqual(["toolCalls"]);
  const withText = [{ kind: "spacer" }, { kind: "thinking", hidden: true }, { kind: "spacer" }, { kind: "text" }];
  expect(withoutThinking(withText).map((p) => p.kind)).toEqual(["spacer", "text"]);
});
