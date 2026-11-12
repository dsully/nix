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
  ["rg -m 5 foo x.ts", "grep", { pattern: "foo", path: "x.ts", limit: 5 }],
  ["grep -m3 foo x.txt", "grep", { pattern: "foo", path: "x.txt", limit: 3 }],
  ["rg --max-count=2 foo x.ts", "grep", { pattern: "foo", path: "x.ts", limit: 2 }],
  ["rg foo src | head -20", "grep", { pattern: "foo", path: "src", limit: 20 }],
  ["grep -rn foo . | head", "grep", { pattern: "foo", path: ".", limit: 10 }],
  ["rg 'a|b' x.ts | head -n 3", "grep", { pattern: "a|b", path: "x.ts", limit: 3 }],
  ["rg -m 5 foo x.ts | head -2", "grep", { pattern: "foo", path: "x.ts", limit: 2 }],
  ["cat x.ts | head -80", "read", { path: "x.ts", limit: 80 }],
  ["head -100 x.ts | head -n 20", "read", { path: "x.ts", limit: 20 }],
  ["tail -n +40 x.ts | head -5", "read", { path: "x.ts", offset: 40, limit: 5 }],
  ["find . -name '*.nix' | head -5", "find", { pattern: "*.nix", path: ".", limit: 5 }],
  ["fd -e nix | head --lines=3", "find", { pattern: "*.nix", limit: 3 }],
])("translates %p to %s", (command, tool, args) => {
  const translation = translate(command);
  expect(translation?.tool).toBe(tool);
  expect(translation?.args).toMatchObject(args);
});

test("only a per-file max count needs the caller to confirm a file path", () => {
  expect(translate("rg -m 5 foo x.ts")?.fileOnly).toBe(true);
  expect(translate("rg -m 5 foo x.ts | head -2")?.fileOnly).toBe(true);
  expect(translate("rg foo x.ts | head -2")?.fileOnly).toBeUndefined();
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
  "rg -m 5 foo",
  "grep -r -m 5 foo",
  "rg -C 2 foo | head -20",
  "rg foo | head -c 10",
  "rg foo | head -5 other.txt",
  "rg foo | tail -5",
  "rg foo |& head -5",
  "rg foo | head -5 | wc -l",
  "rg -c foo | head",
  "head -5 | rg foo",
  'cat "$HOME/x"',
  "cat 'unterminated",
])("does not translate %p", (command) => {
  expect(translate(command)).toBeUndefined();
});
