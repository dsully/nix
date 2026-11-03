import { expect, test } from "bun:test";
import { MAX_CHARS, MAX_LINES, preview } from "./compact.js";

const lines = (n: number, width = 1) => Array.from({ length: n }, (_, i) => String(i).padEnd(width, "x")).join("\n");

test("small output passes through", () => {
  expect(preview(lines(MAX_LINES), false)).toBeUndefined();
});

test("long output keeps head and tail lines", () => {
  const out = preview(lines(1000), false)!;
  const kept = out.split("\n");
  expect(kept[0]).toBe("0");
  expect(kept[99]).toBe("99");
  expect(kept).toContain("... 840 lines omitted ...");
  expect(kept.at(-1)).toBe("999");
  expect(kept.at(-60)).toBe("940");
});

test("errors keep more lines", () => {
  expect(preview(lines(1000), true)!).toContain("... 720 lines omitted ...");
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
