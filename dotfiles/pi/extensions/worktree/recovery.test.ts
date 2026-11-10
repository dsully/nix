import { afterEach, beforeEach, expect, test } from "bun:test";
import { execFileSync } from "node:child_process";
import { mkdirSync, mkdtempSync, realpathSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { isUsable, recoveryTarget, takeSnapshot } from "./recovery.js";

let base: string;
let main: string;
let feature: string;

const git = (cwd: string, ...args: string[]) => execFileSync("git", args, { cwd, stdio: "pipe" });

beforeEach(() => {
  base = realpathSync(mkdtempSync(join(tmpdir(), "wt-recovery-")));
  main = join(base, "repo");
  feature = join(main, ".worktrees", "feat");
  mkdirSync(main);
  git(main, "init", "-q", "-b", "main");
  git(main, "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "--allow-empty", "-m", "init");
  git(main, "-c", "core.logAllRefUpdates=false", "worktree", "add", "-q", "-b", "feat", feature);
});

afterEach(() => rmSync(base, { recursive: true, force: true }));

test("snapshot records the worktree, its branch and the main checkout first", async () => {
  const snap = (await takeSnapshot(feature))!;
  expect(snap.path).toBe(feature);
  expect(snap.branch).toBe("feat");
  expect(snap.worktrees[0]!.path).toBe(main);
});

test("outside a repository there is no snapshot", async () => {
  expect(await takeSnapshot(base)).toBeUndefined();
});

test("a deleted worktree is unusable and recovers to the main checkout", async () => {
  const snap = (await takeSnapshot(feature))!;
  expect(await isUsable(feature, snap)).toBe(true);
  rmSync(feature, { recursive: true, force: true });
  expect(await isUsable(feature, snap)).toBe(false);
  expect((await recoveryTarget(snap))?.path).toBe(main);
});

test("a plain directory left at the worktree path is unusable", async () => {
  const snap = (await takeSnapshot(feature))!;
  rmSync(feature, { recursive: true, force: true });
  mkdirSync(feature);
  expect(await isUsable(feature, snap)).toBe(false);
});

test("with the main checkout gone no worktree of the repository survives", async () => {
  const snap = (await takeSnapshot(feature))!;
  rmSync(main, { recursive: true, force: true });
  expect(await recoveryTarget(snap)).toBeUndefined();
});

test("a directory the snapshot does not cover only needs to exist", async () => {
  const snap = (await takeSnapshot(feature))!;
  expect(await isUsable(base, snap)).toBe(true);
  expect(await isUsable(join(base, "missing"), snap)).toBe(false);
});
