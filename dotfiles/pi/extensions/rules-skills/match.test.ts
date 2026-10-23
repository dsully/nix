import { mkdirSync, mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { expect, test } from "bun:test";
import { gitRoot, wanted } from "./match.js";

const repo = (files: string[]) => {
  const dir = mkdtempSync(join(tmpdir(), "rules-skills-"));
  mkdirSync(join(dir, ".git"));
  for (const file of files) writeFileSync(join(dir, file), "");
  return dir;
};

test("git root is found from a subdirectory", () => {
  const dir = repo([]);
  mkdirSync(join(dir, "a", "b"), { recursive: true });
  expect(gitRoot(join(dir, "a", "b"))).toBe(dir);
});

test("rust repo gets rust-rules only", () => {
  expect(wanted(repo(["Cargo.toml"]))).toEqual(["rust-rules"]);
});

test("pyproject.toml or a root .py file gets python-rules", () => {
  expect(wanted(repo(["pyproject.toml"]))).toEqual(["python-rules"]);
  expect(wanted(repo(["setup.py"]))).toEqual(["python-rules"]);
});

test("repo with neither gets none", () => {
  expect(wanted(repo(["flake.nix"]))).toEqual([]);
});
