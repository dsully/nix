import { expect, test } from "bun:test";
import { thoughtToolRows } from "./grouping.js";

test("groups tools beneath a thought until the next assistant block", () => {
  const first = { toolName: "codemode" };
  const second = { toolName: "read" };
  const rows = thoughtToolRows([
    { hiddenThinkingLabel: "│ * Thought: Read the skill" },
    first,
    second,
    { hiddenThinkingLabel: "│ * Thought: Summarize the skill" },
  ]);
  expect([...rows]).toEqual([
    [first, false],
    [second, true],
  ]);
});

test("does not group tools beneath ordinary assistant or text blocks", () => {
  const tool = { toolName: "read" };
  expect(
    thoughtToolRows([
      { hiddenThinkingLabel: "assistant text" },
      tool,
      { kind: "text" },
      { hiddenThinkingLabel: "│ * Thought: later thought" },
    ]),
  ).toEqual(new Map());
});
