import { expect, test } from "bun:test";
import { MAX_CHARS, MAX_LINES, preview } from "./compact.js";

const lines = (n: number, width = 1) => Array.from({ length: n }, (_, i) => String(i).padEnd(width, "x")).join("\n");

test("small output passes through", () => {
  expect(preview(lines(MAX_LINES), false)).toBeUndefined();
});

test("long output keeps head and tail lines", () => {
  const kept = preview(lines(1000), false)!.split("\n");
  expect(kept[0]).toBe("0");
  expect(kept.at(-1)).toBe("999");
  expect(kept.some((line) => /^\.\.\. \d+ lines omitted \.\.\.$/.test(line))).toBe(true);
  expect(kept.length).toBeLessThan(MAX_LINES * 2);
});

test("errors keep more lines", () => {
  const count = (isError: boolean) => preview(lines(1000), isError)!.split("\n").length;
  expect(count(true)).toBeGreaterThan(count(false));
});

test("few very long lines are cut by characters", () => {
  const out = preview(lines(10, 5000), false)!;
  expect(out.length).toBeLessThan(MAX_CHARS + 100);
  expect(out.startsWith("0xx")).toBe(true);
  expect(out).toMatch(/\.\.\. \d+ characters omitted \.\.\./);
});

test("line cut that is still too wide is also cut by characters", () => {
  const out = preview(lines(1000, 500), false)!;
  expect(out.length).toBeLessThan(MAX_CHARS + 100);
});
