import { existsSync } from "node:fs";
import { dirname, join } from "node:path";

/** Every `.claude/skills` from `cwd` up to its git root, nearest first; none outside a git repo. */
export function claudeSkillDirs(cwd: string): string[] {
  const dirs: string[] = [];
  for (let dir = cwd; dirname(dir) !== dir; dir = dirname(dir)) {
    const skills = join(dir, ".claude", "skills");
    if (existsSync(skills)) dirs.push(skills);
    if (existsSync(join(dir, ".git"))) return dirs;
  }
  return [];
}
