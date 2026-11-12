import { expect, test } from "bun:test";
import { interception, RULES } from "./interceptor.js";

const all = [...new Set(RULES.map((rule) => rule.tool))];

test.each([
  ["cat package.json", "read"],
  ["head -20 README.md", "read"],
  ["rg foo src", "grep"],
  ["cd src && grep -n foo bar.ts", "grep"],
  ["cat a.ts; head -5 b.ts", "read"],
  ["cat x.ts | grep foo", "read"],
  ["git status && npm run dev", "bg_run"],
  ["ls && echo hi > out.txt", "write"],
  ["git diff; sed -i 's/a/b/' x", "replace"],
  ["FOO=1 rg foo", "grep"],
  ["rg -g '*.nix' -i foo", "grep"],
  ["find . -name '*.nix'", "find"],
  ["sed -i 's/a/b/' x", "replace"],
  ['echo "hi" > out.txt', "write"],
  ["cat <<EOF > out.txt\nhi\nEOF", "write"],
  ["nohup server", "bg_run"],
  ["npm run dev", "bg_run"],
  ["vitest --watch", "bg_run"],
])("blocks %p (suggests %s)", (command, tool) => {
  expect(interception(command, all)).toBeDefined();
  expect(
    interception(
      command,
      all.filter((name) => name !== tool),
    ),
  ).toBeUndefined();
});

test.each([
  "git log | grep fix",
  "curl -s url | head -5",
  "ls -la",
  "sed -n 1,5p x",
  'echo "a -> b"',
  "echo hi > /dev/null",
  "nix build .#foo",
  "rg -c foo src",
  "cd src && grep -rln foo .",
  "rg --files-with-matches foo",
  "grep -v foo x.txt",
  "rg foo --glob '!*.test.ts'",
  "rg -g '!vendor' foo",
  "rg --no-ignore foo",
  "rg -m 1 foo src",
  "rg -m1 foo src",
  "grep -rm 2 foo src",
  "rg --max-count=1 foo src",
  'which pi; git status --short | head; cat shared/setup.ts | head -50; grep -rn "PI_MIN_VERSION" --include=*.ts .',
  "cat package.json && git log -1",
  "git status; find . -name '*.nix'",
  "head -3 flake.nix | wc -l",
  "cat package.json | jq .name",
])("allows %p", (command) => {
  expect(interception(command, all)).toBeUndefined();
});
