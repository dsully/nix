import { mkdirSync, mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { expect, test } from "bun:test";
import { rulesSkillsFor } from "../rules-skills.js";

const repo = (files: string[]) => {
  const dir = mkdtempSync(join(tmpdir(), "rules-skills-"));
  mkdirSync(join(dir, ".git"));
  for (const file of files) writeFileSync(join(dir, file), "");
  return dir;
};

test("rust repo gets rust-rules only", () => {
  expect(rulesSkillsFor(repo(["Cargo.toml"]))).toEqual(["rust-rules"]);
});

test("pyproject.toml or a root .py file gets python-rules", () => {
  expect(rulesSkillsFor(repo(["pyproject.toml"]))).toEqual(["python-rules"]);
  expect(rulesSkillsFor(repo(["setup.py"]))).toEqual(["python-rules"]);
});

test("repo with neither gets none", () => {
  expect(rulesSkillsFor(repo(["flake.nix"]))).toEqual([]);
});
