import { expect, test } from "bun:test";
import { tmpdir } from "node:os";
import { shortCommand } from "./command.ts";

const cwd = process.cwd();

test("drops cds into cwd and keeps the last part of another folder", () => {
  expect(shortCommand(`cd ${cwd} && make`, cwd)).toBe("make");
  expect(shortCommand(`cd ${tmpdir()} && make`, cwd)).toStartWith("cd …/");
  expect(shortCommand(`cd ${tmpdir()} && make`, cwd)).toEndWith(" && make");
});

test("drops leading settings and the script's folder, keeping only the first line", () => {
  expect(shortCommand("PYTHONPATH=/a/src FOO='x y' ./scripts/run.sh --fast\necho done", cwd)).toBe("run.sh --fast");
});

test("caps at max with an ellipsis", () => {
  const shown = shortCommand("x".repeat(80), cwd, 50);
  expect(shown).toHaveLength(50);
  expect(shown).toEndWith("…");
});
