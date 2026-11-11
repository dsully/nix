import { expect, test } from "bun:test";
import { grepRows, listRows, matchRanges, readRows } from "./code.js";

test("anchored rows are numbered from the start line; other lines stay notes", () => {
  const rows = readRows("abCD│const a = 1;\nefGH│\n\n[Showing lines 7-8 of 9.]", 7);
  expect(rows?.filter((row) => row.kind === "code")).toEqual([
    { kind: "code", line: 7, anchor: "abCD", text: "const a = 1;" },
    { kind: "code", line: 8, anchor: "efGH", text: "" },
  ]);
  expect(rows?.at(-1)).toEqual({ kind: "note", text: "[Showing lines 7-8 of 9.]" });
});

test("text without anchored rows is not a hashline read", () => {
  expect(readRows("Read image file [image/png]", 1)).toBeUndefined();
});

test("grep output splits into file headers, match and context hits, and notes", () => {
  const rows = grepRows("=== src/a.ts ===\n 9-│ abCD│before\n10:│ efGH│const x = 1;\n\n[grep: 1 line(s) exceed 500B]");
  expect(rows).toEqual([
    { kind: "file", path: "src/a.ts" },
    { kind: "hit", line: 9, match: false, anchor: "abCD", text: "before" },
    { kind: "hit", line: 10, match: true, anchor: "efGH", text: "const x = 1;" },
    { kind: "note", text: "" },
    { kind: "note", text: "[grep: 1 line(s) exceed 500B]" },
  ]);
});

test("grep output without hits is not a hashline grep", () => {
  expect(grepRows("No matches found")).toBeUndefined();
});

test("match ranges follow the grep call's literal and case flags", () => {
  expect(matchRanges("a.b axb A.B", { pattern: "a.b", literal: true })).toEqual([[0, 3]]);
  expect(matchRanges("a.b axb A.B", { pattern: "a.b", literal: true, ignoreCase: true })).toEqual([
    [0, 3],
    [8, 11],
  ]);
  expect(matchRanges("a.b axb", { pattern: "a.b" })).toEqual([
    [0, 3],
    [4, 7],
  ]);
  expect(matchRanges("abc", { pattern: "(" })).toEqual([]);
});

test("ls output marks directories by their slash and keeps notes apart", () => {
  expect(listRows("lib/\nindex.ts\n\n[500 entries limit reached]\n")).toEqual([
    { kind: "entry", name: "lib", dir: true },
    { kind: "entry", name: "index.ts", dir: false },
    { kind: "note", text: "" },
    { kind: "note", text: "[500 entries limit reached]" },
  ]);
});
