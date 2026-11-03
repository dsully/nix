import { existsSync } from "node:fs";
import { dirname, join } from "node:path";

/** Nearest directory holding `.git` (a directory, or a file in worktrees), or undefined outside a repo. */
export function gitRoot(cwd: string): string | undefined {
  for (let dir = cwd; ; dir = dirname(dir)) {
    if (existsSync(join(dir, ".git"))) return dir;
    if (dirname(dir) === dir) return undefined;
  }
}
