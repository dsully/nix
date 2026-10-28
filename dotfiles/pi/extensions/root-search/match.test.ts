import { expect, test } from "bun:test";
import { searchesTooBroadly } from "./match.js";

test.each([
  "find / -name foo",
  "find /",
  "sudo find / -type f",
  "find -L / -name x",
  "find /* -name x",
  "find '/' -name x",
  "ls; find / -name x 2>/dev/null",
  "echo $(find / -name x)",
  "fd foo /",
  "fd -H -e nix foo / | head",
  "fd --search-path / foo",
  "fd --search-path=/ foo",
  "fd --base-directory / foo",
  "find /nix/store -name '*.nix'",
  "find /nix -name x",
  "fd foo /nix/store",
  "fd -e nix foo /nix/store/",
  "fd --search-path=/nix/store foo",
  "sudo fd foo /nix",
  "rg pattern /nix/store",
  "grep -r foo /nix/store/* | head",
])("blocks %p", (command) => {
  expect(searchesTooBroadly(command)).toBe(true);
});

test.each([
  "find . -name foo",
  "find ./ -name foo",
  "find /tmp -name foo",
  "find ~/ -name foo",
  "find src -path '*/x/*'",
  "fd foo",
  "fd -e nix foo ~/dev",
  "locate foo",
  "rg 'find /' docs",
  "grep -r x / --include=*.nix | wc -l && fd foo .",
  "fd foo /nix/store/abc123-hello-2.12",
  "find /nix/store/abc123-hello-2.12/bin -type f",
  "rg foo $(nix eval --raw .#hello.outPath)",
  "nix-locate bin/hello",
  "nix path-info -r .#hello | rg hello",
  "nix-store -qR /nix/store/abc123-hello-2.12 | grep openssl",
])("allows %p", (command) => {
  expect(searchesTooBroadly(command)).toBe(false);
});
