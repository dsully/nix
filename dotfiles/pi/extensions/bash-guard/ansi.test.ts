import { expect, test } from "bun:test";
import { stripAnsi } from "./ansi.js";

const ESC = "\x1b";

test.each([
  [`${ESC}[0m${ESC}[1m${ESC}[34msrc/a.py${ESC}[0m`, "src/a.py"],
  [`${ESC}[32m12${ESC}[0m:    ${ESC}[36mdef${ESC}[0m f()`, "12:    def f()"],
  [`${ESC}]8;;file:///a${ESC}\\a${ESC}]8;;${ESC}\\`, "a"],
  [`${ESC}]8;;file:///a\x07a${ESC}]8;;\x07`, "a"],
  [`a${ESC}[2Kb${ESC}[?25l`, "ab"],
  ["plain text\n", "plain text\n"],
])("strips escapes from %p", (input, expected) => {
  expect(stripAnsi(input)).toBe(expected);
});
