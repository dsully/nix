import { expect, test } from "bun:test";
import { applyInlineFlags, negatedGlobReason } from "./grep-flags.js";

test.each([
  [{ pattern: "(?i)tracked radars" }, { pattern: "tracked radars", ignoreCase: true }],
  [
    { pattern: "(?i)foo", path: "src" },
    { pattern: "foo", path: "src", ignoreCase: true },
  ],
  [
    { pattern: "(?i)foo", ignoreCase: false },
    { pattern: "foo", ignoreCase: true },
  ],
])("rewrites %p", (input, expected) => {
  const copy: Record<string, unknown> = { ...input };
  applyInlineFlags(copy);
  expect(copy).toEqual(expected);
});

test.each([
  { pattern: "tracked radars" },
  { pattern: "(?i)foo", literal: true },
  { pattern: "foo(?i)bar" },
  { pattern: "(?s)foo" },
  { pattern: "(?i)" },
])("leaves %p as is", (input) => {
  const copy: Record<string, unknown> = { ...input };
  applyInlineFlags(copy);
  expect(copy).toEqual(input);
});

test.each([{ glob: "!**/tests/**" }, { glob: " !*.ts" }])("rejects the negated glob in %p", (input) => {
  expect(negatedGlobReason({ pattern: "foo", ...input })).toContain("rg -g");
});

test.each([{}, { glob: "*.ts" }, { glob: "**/!x" }])("accepts the glob in %p", (input) => {
  expect(negatedGlobReason({ pattern: "foo", ...input })).toBeUndefined();
});
