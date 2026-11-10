import { statSync } from "node:fs";
import { run } from "../lib/exec.js";

export interface Worktree {
  path: string;
  branch?: string;
}

/** A session's worktree, captured while it exists: Git cannot find its repository after removal. */
export interface Snapshot {
  cwd: string;
  path: string;
  branch?: string;
  gitDir: string;
  commonDir: string;
  /** Main checkout first, as `git worktree list` orders them. */
  worktrees: Worktree[];
}

export function parseWorktreeList(porcelain: string): Worktree[] {
  return porcelain
    .trim()
    .split("\n\n")
    .filter(Boolean)
    .map((block) => {
      const lines = block.split("\n");
      const path = lines.find((l) => l.startsWith("worktree "))!.slice(9);
      const ref = lines.find((l) => l.startsWith("branch "))?.slice(7);
      return { path, branch: ref?.replace(/^refs\/heads\//, "") };
    });
}

function isDirectory(path: string): boolean {
  try {
    return statSync(path).isDirectory();
  } catch {
    return false;
  }
}

async function gitLines(cwd: string, args: string[]): Promise<string[] | undefined> {
  if (!isDirectory(cwd)) return undefined;
  const r = await run("git", args, undefined, cwd, 5_000);
  return r.code === 0 ? r.stdout.trim().split("\n") : undefined;
}

const LOCATE = ["rev-parse", "--path-format=absolute", "--show-toplevel", "--absolute-git-dir", "--git-common-dir"];

export async function takeSnapshot(cwd: string): Promise<Snapshot | undefined> {
  const [path, gitDir, commonDir] = (await gitLines(cwd, LOCATE)) ?? [];
  if (!path || !gitDir || !commonDir) return undefined;
  const list = await run("git", ["worktree", "list", "--porcelain"], undefined, cwd, 5_000);
  if (list.code !== 0) return undefined;
  const worktrees = parseWorktreeList(list.stdout);
  const branch = worktrees.find((w) => w.path === path)?.branch;
  return { cwd, path, branch, gitDir, commonDir, worktrees };
}

/** A directory the snapshot does not cover only needs to exist; the snapshot's own cwd must still be its worktree. */
export async function isUsable(cwd: string, snap?: Snapshot): Promise<boolean> {
  if (!isDirectory(cwd)) return false;
  if (snap?.cwd !== cwd) return true;
  const [, gitDir] = (await gitLines(cwd, LOCATE)) ?? [];
  return gitDir === snap.gitDir;
}

export async function recoveryTarget(snap: Snapshot): Promise<Worktree | undefined> {
  for (const worktree of snap.worktrees) {
    if (worktree.path === snap.path) continue;
    const [path, , commonDir] = (await gitLines(worktree.path, LOCATE)) ?? [];
    if (path === worktree.path && commonDir === snap.commonDir) return worktree;
  }
  return undefined;
}
