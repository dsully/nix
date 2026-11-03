import { existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { gitRoot } from "../lib/git-root.js";

/** Every `.claude/skills` from `cwd` up to its git root, nearest first; none outside a git repo. */
export function claudeSkillDirs(cwd: string): string[] {
  const root = gitRoot(cwd);
  if (!root) return [];
  const dirs: string[] = [];
  for (let dir = cwd; ; dir = dirname(dir)) {
    const skills = join(dir, ".claude", "skills");
    if (existsSync(skills)) dirs.push(skills);
    if (dir === root) return dirs;
  }
}
