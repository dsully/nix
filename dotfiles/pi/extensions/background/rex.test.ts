import { expect, test } from "bun:test";
import { newLines } from "./rex.ts";

test("passes on new lines and a redrawn last line again", () => {
  const first = newLines("a\nprogress 10%\n", 0);
  expect(first).toEqual({ text: "a\nprogress 10%\n", sent: 2, last: "progress 10%" });
  expect(newLines("a\nprogress 100%\nb\n", first.sent, first.last).text).toBe("progress 100%\nb\n");
});

test("passes nothing on for an empty or unchanged capture", () => {
  expect(newLines("\n", 0).text).toBe("");
  expect(newLines("a\nb\n", 2, "b").text).toBe("");
});
