import { expect, test } from "bun:test";
import { translate } from "./translate.js";

test.each([
  ["cat package.json", "read", { path: "package.json" }],
  ["cat 'a b.txt'", "read", { path: "a b.txt" }],
  ["head README.md", "read", { path: "README.md", limit: 10 }],
  ["head -20 README.md", "read", { path: "README.md", limit: 20 }],
  ["head -n 5 x.ts", "read", { path: "x.ts", limit: 5 }],
  ["head --lines=7 x.ts", "read", { path: "x.ts", limit: 7 }],
  ["tail -n +40 x.ts", "read", { path: "x.ts", offset: 40 }],
  ["tail -30 x.ts", "read", { path: "x.ts" }],
  ["rg foo", "grep", { pattern: "foo" }],
  ["rg -i foo src", "grep", { pattern: "foo", path: "src", ignoreCase: true }],
  ["rg -F 'a.b(' src", "grep", { pattern: "a.b(", literal: true }],
  ["rg -n -C 3 foo", "grep", { pattern: "foo", context: 3 }],
  ["rg -g '*.nix' foo modules", "grep", { pattern: "foo", path: "modules", glob: "*.nix" }],
  ["grep -rn foo .", "grep", { pattern: "foo", path: "." }],
  ["grep foo x.txt", "grep", { pattern: "foo", path: "x.txt" }],
  ["grep -rn --include=*.ts PI_MIN .", "grep", { pattern: "PI_MIN", glob: "*.ts" }],
  ["grep -E 'a|b' x.txt", "grep", { pattern: "a|b" }],
  ["grep 'a\\|b' x.txt", "grep", { pattern: "a|b" }],
  ["grep 'a+' x.txt", "grep", { pattern: String.raw`a\+` }],
  [String.raw`grep -n '\\|' SKILL.md`, "grep", { pattern: String.raw`\\\|`, path: "SKILL.md" }],
  ["grep -F 'a+' x.txt", "grep", { pattern: "a+", literal: true }],
  ["find . -name '*.nix'", "find", { pattern: "*.nix", path: "." }],
  ["find modules -type f -name '*.nix'", "find", { pattern: "*.nix", path: "modules" }],
  ["fd -g '*.ts' src", "find", { pattern: "*.ts", path: "src" }],
  ["fd -e nix", "find", { pattern: "*.nix" }],
])("translates %p to %s", (command, tool, args) => {
  const translation = translate(command);
  expect(translation?.tool).toBe(tool);
  expect(translation?.args).toMatchObject(args);
});

test("tail keeps the line count for the caller", () => {
  expect(translate("tail -30 x.ts")?.tailLines).toBe(30);
});

test.each([
  "cat a.ts b.ts",
  "cat -n x.ts",
  "cat *.ts",
  "cat $FILE",
  "cat ~/x",
  "cat x | jq .",
  "cat x > y",
  "cd src && cat x",
  "FOO=1 cat x",
  "head -c 10 x",
  "tail -f log",
  "rg -c foo",
  "rg -w foo",
  "rg -t rust foo",
  "rg foo a b",
  "rg -g '!vendor' foo",
  "grep foo",
  "grep '\\<a' x.txt",
  "grep --include=*.ts --include=*.js foo .",
  "find . -iname x",
  "find . -maxdepth 1 -name x",
  "find . -name a -name b",
  "fd foo",
  "fd -g x -e nix",
  'cat "$HOME/x"',
  "cat 'unterminated",
])("does not translate %p", (command) => {
  expect(translate(command)).toBeUndefined();
});
