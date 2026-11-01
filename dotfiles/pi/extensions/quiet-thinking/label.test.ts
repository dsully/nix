import { expect, test } from "bun:test";
import { collapseThinking, presentThought, thinkingLine } from "./label.js";

test("keeps the last hidden thinking row and drops the spacer stack", () => {
  expect(
    collapseThinking([
      { kind: "spacer" },
      { kind: "thinking", hidden: true },
      { kind: "spacer" },
      { kind: "thinking", hidden: true },
      { kind: "spacer" },
      { kind: "tool" },
    ]),
  ).toEqual([{ kind: "thinking", hidden: true }, { kind: "spacer" }, { kind: "tool" }]);
});

test("leaves a message with no hidden thinking alone", () => {
  const parts = [{ kind: "text" }];
  expect(collapseThinking(parts)).toBe(parts);
});

test("settled thought shows the first line and keeps a duration", () => {
  expect(presentThought("│ * Thought · 2.5s", "The build failed in quiet-tools.")).toBe(
    "│ * Thought: The build failed in quiet-tools. · 2.5s",
  );
});

test("live spinner is left to the merger", () => {
  expect(presentThought("│ ⠋ Thinking…", "still going")).toBeUndefined();
});

test("uses the first visible thinking line", () => {
  expect(thinkingLine([{ type: "thinking", thinking: "\n  The build failed.\nmore" }])).toBe("The build failed.");
});
