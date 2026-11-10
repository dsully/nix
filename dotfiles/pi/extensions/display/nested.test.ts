import { expect, test } from "bun:test";
import { nestedResultLines } from "./nested.js";

const text = ["Agent: a1", "Type: explore | Status: completed", "line 2", "line 3", "line 4"].join("\n");

test("collapsed result keeps a nested preview", () => {
  expect(nestedResultLines(text, false)).toEqual([
    "Agent: a1",
    "  ⎿ Type: explore | Status: completed",
    "    line 2",
    "    line 3",
    "    … 1 more",
  ]);
});

test("expanded result shows the rest of the preview", () => {
  expect(nestedResultLines(text, true).at(-1)).toBe("    line 4");
});

test("empty result is explicit", () => {
  expect(nestedResultLines("  \n", false)).toEqual(["(no result)"]);
});
