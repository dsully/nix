import { existsSync, readdirSync } from "node:fs";
import { dirname, join } from "node:path";

// Skill name -> it is offered only when the git root matches.
const MARKERS: Record<string, (files: string[]) => boolean> = {
  "python-rules": (files) => files.includes("pyproject.toml") || files.some((f) => f.endsWith(".py")),
  "rust-rules": (files) => files.includes("Cargo.toml"),
};

/** Nearest directory holding `.git` (a directory, or a file in worktrees), else `cwd`. */
export function gitRoot(cwd: string): string {
  for (let dir = cwd; ; dir = dirname(dir)) {
    if (existsSync(join(dir, ".git"))) return dir;
    if (dirname(dir) === dir) return cwd;
  }
}

export function wanted(root: string): string[] {
  let files: string[];
  try {
    files = readdirSync(root);
  } catch {
    files = [];
  }
  return Object.keys(MARKERS).filter((name) => MARKERS[name]!(files));
}
