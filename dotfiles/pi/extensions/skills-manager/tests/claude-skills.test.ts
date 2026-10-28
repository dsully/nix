import { expect, test } from "bun:test";
import { mkdirSync, mkdtempSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { claudeSkillDirs } from "../claude-skills.ts";

const tree = (dirs: string[]) => {
  const root = mkdtempSync(join(tmpdir(), "claude-skills-"));
  for (const dir of dirs) mkdirSync(join(root, dir), { recursive: true });
  return root;
};

test("collects nested and repo-root skills, nearest first, stopping at the git root", () => {
  const root = tree(["repo/.git", "repo/.claude/skills", "repo/pkg/.claude/skills", ".claude/skills"]);
  expect(claudeSkillDirs(join(root, "repo/pkg"))).toEqual([
    join(root, "repo/pkg/.claude/skills"),
    join(root, "repo/.claude/skills"),
  ]);
});

test("returns nothing outside a git repo", () => {
  const root = tree([".claude/skills", "sub"]);
  expect(claudeSkillDirs(join(root, "sub"))).toEqual([]);
});

test("returns nothing when the repo has no .claude/skills", () => {
  const root = tree(["repo/.git"]);
  expect(claudeSkillDirs(join(root, "repo"))).toEqual([]);
});
