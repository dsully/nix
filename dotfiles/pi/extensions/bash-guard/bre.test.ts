import { expect, test } from "bun:test";
import { breToRegex } from "./bre.js";

test.each([
  [String.raw`a\|b`, "a|b"],
  [String.raw`\\|`, String.raw`\\\|`],
  ["a+b?", String.raw`a\+b\?`],
  ["f(x){y}", String.raw`f\(x\)\{y\}`],
  [String.raw`\(ab\)\+`, "(ab)+"],
  [String.raw`a\{2,3\}`, "a{2,3}"],
  [String.raw`a\{2\}`, "a{2}"],
  ["*a", String.raw`\*a`],
  ["^*a", String.raw`^\*a`],
  [String.raw`\(*a\)`, String.raw`(\*a)`],
  ["^a$", "^a$"],
  ["a^b$c", String.raw`a\^b\$c`],
  [String.raw`\(a$\|^b\)`, "(a$|^b)"],
  ["[]|(]", String.raw`[\]|(]`],
  ["[^]a]", String.raw`[^\]a]`],
  [String.raw`[a\b]`, String.raw`[a\\b]`],
  ["[a[b]", String.raw`[a\[b]`],
  [String.raw`\w\+\.ts`, String.raw`\w+\.ts`],
  [String.raw`\bfoo\B`, String.raw`\bfoo\B`],
  [String.raw`a\/b`, "a/b"],
  ["plain-text_1 ok", "plain-text_1 ok"],
])("converts %p to %p", (bre, regex) => {
  expect(breToRegex(bre)).toBe(regex);
});

test.each([
  String.raw`\<word\>`,
  String.raw`\(a\)\1`,
  "[[:alpha:]]",
  "[[.a.]]",
  "[a&&b]",
  "[a~~b]",
  String.raw`\+a`,
  String.raw`\(\?a\)`,
  String.raw`a\{,3\}`,
  String.raw`a\{2`,
  String.raw`a\}`,
  "a**",
  "trailing\\",
  "[abc",
  String.raw`a\n`,
  String.raw`\b*`,
])("refuses %p", (bre) => {
  expect(breToRegex(bre)).toBeUndefined();
});

test("every conversion is a valid unicode-mode RegExp", () => {
  const samples = [
    String.raw`a\|b`,
    String.raw`\\|`,
    "f(x){y}",
    "*a",
    "a^b$c",
    "[]|(]",
    String.raw`[a\b]`,
    "[a[b]",
    "a-b~c&d<e>#",
  ];
  for (const sample of samples) {
    const regex = breToRegex(sample);
    expect(regex).toBeDefined();
    expect(() => new RegExp(regex as string, "u")).not.toThrow();
  }
});
