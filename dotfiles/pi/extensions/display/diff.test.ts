import { expect, test } from "bun:test";
import { keepBackground, markRanges, markWords, parseUnified, patchPath, trimContext, wordRanges } from "./diff.js";

const patch = [
  "--- a/src/a.ts",
  "+++ b/src/a.ts",
  "@@ -10,4 +10,4 @@",
  " one",
  "-const x = 1;",
  "+const x = 2;",
  " two",
  " three",
  "@@ -40,2 +40,3 @@",
  " four",
  "+five",
  "",
].join("\n");

test("the path comes from the +++ header", () => {
  expect(patchPath(patch)).toBe("src/a.ts");
  expect(patchPath("--- a\n+++ /dev/null\n")).toBeUndefined();
});

test("removed lines carry old numbers, the rest new ones, with a gap between hunks", () => {
  const lines = parseUnified(patch);
  expect(lines.find((l) => l.kind === "del")).toMatchObject({ line: 11, text: "const x = 1;" });
  expect(lines.find((l) => l.kind === "add")).toMatchObject({ line: 11, text: "const x = 2;" });
  expect(lines.filter((l) => l.kind === "gap")).toHaveLength(1);
  expect(lines.at(-1)).toMatchObject({ kind: "add", line: 41, text: "five" });
});

test("only the changed words are marked on a replaced line", () => {
  const [removed, added] = wordRanges("const x = 1;", "const x = 2;")!;
  expect(removed.map(([s, e]) => "const x = 1;".slice(s, e))).toEqual(["1"]);
  expect(added.map(([s, e]) => "const x = 2;".slice(s, e))).toEqual(["2"]);
});

test("marks pair removed and added lines one to one", () => {
  const marked = markWords(parseUnified(patch));
  expect(marked.find((l) => l.kind === "add")?.marks).toBeDefined();
  expect(marked.find((l) => l.text === "five")?.marks).toBeUndefined();
});

test("trimmed context keeps changes and their neighbors", () => {
  const trimmed = trimContext(parseUnified(patch), 1);
  expect(trimmed.filter((l) => l.kind === "add" || l.kind === "del")).toHaveLength(3);
  expect(trimmed.some((l) => l.text === "three")).toBe(false);
  expect(trimmed.at(-1)?.kind).not.toBe("gap");
});

test("marks land on visible characters, skipping escape codes", () => {
  const ansi = "\x1b[31mab\x1b[39mcd";
  expect(markRanges(ansi, [[1, 3]], "[", "]")).toBe("\x1b[31ma[b\x1b[39mc]d");
});

test("a mark reopens after a reset inside it", () => {
  expect(markRanges("ab\x1b[0mcd", [[1, 3]], "[", "]")).toBe("a[b\x1b[0m[c]d");
  expect(markRanges("ab\x1b[0mcd", [[0, 2]], "[", "]")).toBe("[ab]\x1b[0mcd");
});

test("a band background survives inner resets", () => {
  expect(keepBackground("a\x1b[0mb", "BG")).toBe("a\x1b[0mBGb");
  expect(keepBackground("a\x1b[39mb", "BG")).toBe("a\x1b[39mb");
});
