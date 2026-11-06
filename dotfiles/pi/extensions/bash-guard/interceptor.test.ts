import { expect, test } from "bun:test";
import { interception, RULES } from "./interceptor.js";

const all = [...new Set(RULES.map((rule) => rule.tool))];

test.each([
  ["cat package.json", "read"],
  ["head -20 README.md", "read"],
  ["rg foo src", "grep"],
  ["cd src && grep -n foo bar.ts", "grep"],
  ["FOO=1 rg foo", "grep"],
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
])("allows %p", (command) => {
  expect(interception(command, all)).toBeUndefined();
});
