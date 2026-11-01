import { expect, test } from "bun:test";
import { nestedResultLines, splitNative } from "./nested.js";

const text = ["Agent: a1", "Type: explore | Status: completed", "line 2", "line 3", "line 4"].join("\n");

test("collapsed result keeps a nested preview", () => {
  expect(nestedResultLines(text, false)).toEqual([
    "Agent: a1",
    "  └ Type: explore | Status: completed",
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

test("native rows split out of the collapsed group", () => {
  const rows = [
    { native: false, id: "a" },
    { native: true, id: "bg" },
    { native: false, id: "b" },
  ];
  expect(splitNative(rows)).toEqual([{ grouped: [rows[0]] }, { native: rows[1] }, { grouped: [rows[2]] }]);
});
