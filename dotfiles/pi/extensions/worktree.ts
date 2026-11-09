import { copyFileSync, existsSync, readdirSync, rmdirSync, writeFileSync } from "node:fs";
import { join, relative } from "node:path";
import { fuzzyFilter } from "@earendil-works/pi-tui";
import { SessionManager, type ExtensionAPI, type ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { run } from "./lib/exec";
import { errorMessage } from "./lib/error";
import { openWindow, rex, selectWindow } from "./lib/rex";

const WORKTREE_DIR = ".worktrees";
const TOOL_NAME = "worktree";
const LOCAL_CONFIG = /^(\.env(\.[^/]+)?|\.?mise(\.[^/]+)?\.toml)$/;

interface Worktree {
  path: string;
  branch?: string;
}

interface CreatedWorktree extends Worktree {
  root: string;
  branch: string;
  created: boolean;
  copied: string[];
}

interface PendingMove {
  commandArgs: string;
  continuation: string;
}

interface LinkedWorktree {
  root: string;
  path: string;
  branch: string;
}

type WorktreeInfo = {
  branch: string | null;
  path: string;
  main: boolean;
  changes: number | null;
  ahead: number | null;
  behind: number | null;
  tab: string | null;
};

type ToolData = {
  worktrees?: WorktreeInfo[];
  path?: string;
  branch?: string;
  window_id?: string;
  block_id?: string;
};

interface RexWindow {
  window_id: string;
  label: string;
  layers: { blocks: { block_id: string }[] }[];
}

async function git(cwd: string, args: string[], signal?: AbortSignal): Promise<string> {
  const r = await run("git", args, signal, cwd, 60_000);
  if (r.code !== 0) throw new Error(`git ${args.join(" ")}: ${(r.stderr || r.stdout).trim()}`);
  return r.stdout.trim();
}

// Long timeout: wt runs blocking pre-start hooks such as `uv sync`.
async function wt(cwd: string, args: string[], signal?: AbortSignal): Promise<string> {
  const r = await run("wt", args, signal, cwd, 600_000);
  if (r.code !== 0) throw new Error(`wt ${args.join(" ")}: ${(r.stderr || r.stdout).trim()}`);
  return r.stdout.trim();
}

async function listWorktrees(cwd: string, signal?: AbortSignal): Promise<Worktree[]> {
  const out = await git(cwd, ["worktree", "list", "--porcelain"], signal);
  return out.split("\n\n").map((block) => {
    const lines = block.split("\n");
    const path = lines.find((l) => l.startsWith("worktree "))!.slice(9);
    const ref = lines.find((l) => l.startsWith("branch "))?.slice(7);
    return { path, branch: ref?.replace(/^refs\/heads\//, "") };
  });
}

async function copyLocalConfig(root: string, path: string, signal?: AbortSignal): Promise<string[]> {
  const ignored = await git(root, ["ls-files", "--others", "--ignored", "--exclude-standard", "--directory"], signal);
  const files = ignored.split("\n").filter((f) => LOCAL_CONFIG.test(f));
  for (const file of files) copyFileSync(join(root, file), join(path, file));
  return files;
}

async function ensureWorktree(
  cwd: string,
  branch: string,
  base?: string,
  signal?: AbortSignal,
): Promise<CreatedWorktree> {
  await git(cwd, ["check-ref-format", "--branch", branch], signal);
  const root = (await listWorktrees(cwd, signal))[0]!.path;
  const hasLocal =
    (await run("git", ["show-ref", "--verify", "--quiet", `refs/heads/${branch}`], signal, root)).code === 0;
  const hasRemote =
    !hasLocal &&
    (await git(root, ["for-each-ref", "--format=%(refname:short)", `refs/remotes/*/${branch}`], signal)) !== "";
  const args = ["switch", branch, "--no-cd", "--format", "json"];
  if (!hasLocal && !hasRemote) args.push("--create", "--base", base ?? "@");
  const result = JSON.parse(await wt(root, args, signal)) as { action: string; path: string };
  const created = result.action === "created";
  const copied = created ? await copyLocalConfig(root, result.path, signal) : [];
  return { root, path: result.path, branch, created, copied };
}

function currentWorktree(cwd: string, signal?: AbortSignal): Promise<string> {
  return git(cwd, ["rev-parse", "--show-toplevel"], signal);
}

async function assertRemovable(worktree: Worktree, signal?: AbortSignal): Promise<string> {
  if (!worktree.branch)
    throw new Error(`The worktree at ${worktree.path} has a detached HEAD. Create a branch for its commits first.`);
  const status = await git(worktree.path, ["status", "--porcelain"], signal);
  if (status) {
    const count = status.split("\n").length;
    throw new Error(
      `The worktree at ${worktree.path} has ${count} uncommitted or untracked ${count === 1 ? "file" : "files"}. Commit or stash them, then remove it again.`,
    );
  }
  return worktree.branch;
}

async function finishableWorktree(cwd: string, signal?: AbortSignal): Promise<LinkedWorktree> {
  const worktrees = await listWorktrees(cwd, signal);
  const root = worktrees[0]!.path;
  const path = await currentWorktree(cwd, signal);
  if (path === root) throw new Error("This session is in the main checkout, not in a worktree.");
  const worktree = worktrees.find((w) => w.path === path) ?? { path };
  const branch = await assertRemovable(worktree, signal);
  return { root, path, branch };
}

function removeIfEmpty(dir: string): void {
  if (existsSync(dir) && readdirSync(dir).length === 0) rmdirSync(dir);
}

async function removeWorktree(root: string, path: string, signal?: AbortSignal): Promise<void> {
  await wt(root, ["remove", path, "--no-delete-branch", "--foreground", "--format", "json"], signal);
  removeIfEmpty(join(root, WORKTREE_DIR));
}

async function rexWindows(session: string, signal?: AbortSignal): Promise<RexWindow[]> {
  const out = await rex(["window", "ls", "--json", "-s", session], signal);
  return (JSON.parse(out) as { windows: RexWindow[] }).windows;
}

const tabOf = (windows: RexWindow[], branch: string) => windows.find((w) => w.label === branch);

const firstBlock = (window: RexWindow) => window.layers[0]?.blocks[0]?.block_id ?? "";

async function clearTabLabel(branch: string): Promise<void> {
  const { REX_SESSION, REX_BLOCK } = process.env;
  if (!REX_SESSION || !REX_BLOCK) return;
  const window = (await rexWindows(REX_SESSION)).find((w) =>
    w.layers.some((l) => l.blocks.some((b) => b.block_id === REX_BLOCK)),
  );
  if (window?.label === branch) await rex(["window", "rename", "-s", REX_SESSION, window.window_id, ""]);
}

async function describeWorktrees(cwd: string, signal?: AbortSignal): Promise<WorktreeInfo[]> {
  const worktrees = await listWorktrees(cwd, signal);
  const root = worktrees[0]!;
  const session = process.env.REX_SESSION;
  const windows = session ? await rexWindows(session, signal).catch(() => []) : [];
  return Promise.all(
    worktrees.map(async (w) => {
      const main = w === root;
      const status = await run("git", ["status", "--porcelain"], signal, w.path);
      const counts =
        !main && root.branch && w.branch
          ? await run("git", ["rev-list", "--left-right", "--count", `${root.branch}...${w.branch}`], signal, root.path)
          : undefined;
      const [behind, ahead] = counts?.code === 0 ? counts.stdout.trim().split(/\s+/).map(Number) : [null, null];
      const tab = w.branch ? tabOf(windows, w.branch) : undefined;
      return {
        branch: w.branch ?? null,
        path: w.path,
        main,
        changes: status.code === 0 ? status.stdout.split("\n").filter(Boolean).length : null,
        ahead: ahead ?? null,
        behind: behind ?? null,
        tab: tab?.window_id ?? null,
      };
    }),
  );
}

function formatWorktrees(worktrees: WorktreeInfo[]): string {
  const root = worktrees[0]!.path;
  return worktrees
    .map((w) =>
      [
        w.branch ?? "(detached)",
        relative(root, w.path) || ".",
        w.main ? "main checkout" : undefined,
        w.changes === null ? "missing" : `${w.changes} changed`,
        w.ahead === null ? undefined : `+${w.ahead} -${w.behind}`,
        w.tab ? "Rex tab open" : undefined,
      ]
        .filter(Boolean)
        .join("  "),
    )
    .join("\n");
}

function writeEmptySession(cwd: string): string {
  const session = SessionManager.create(cwd);
  const file = session.getSessionFile();
  if (!file) throw new Error("pi created no session file");
  writeFileSync(file, `${JSON.stringify(session.getHeader())}\n`, {
    flag: "wx",
  });
  return file;
}

function forkSession(ctx: ExtensionCommandContext, target: string): string {
  const source = ctx.sessionManager.getSessionFile();
  if (!source) throw new Error("This session is not saved to disk, so it cannot move.");
  const sessionFile = existsSync(source)
    ? SessionManager.forkFrom(source, target).getSessionFile()
    : writeEmptySession(target);
  if (!sessionFile) throw new Error("pi created no session file");
  return sessionFile;
}

async function switchToSession(
  ctx: ExtensionCommandContext,
  sessionFile: string,
  notice: string,
  continuation?: string,
): Promise<void> {
  await ctx.switchSession(sessionFile, {
    withSession: async (next) => {
      next.ui.notify(notice, "info");
      if (continuation)
        await next.sendMessage({ customType: "worktree", content: continuation, display: true }, { triggerTurn: true });
    },
  });
}

async function finishWorktree(ctx: ExtensionCommandContext, continuation?: string): Promise<void> {
  await ctx.waitForIdle();
  const { root, path, branch } = await finishableWorktree(ctx.cwd);
  const sessionFile = forkSession(ctx, root);
  await removeWorktree(root, path);
  await clearTabLabel(branch).catch(() => {});
  await switchToSession(
    ctx,
    sessionFile,
    `Removed worktree ${path}. Branch ${branch} is kept. Session moved to ${root}`,
    continuation,
  );
}

async function forkToWorktree(ctx: ExtensionCommandContext, branch: string): Promise<void> {
  const session = process.env.REX_SESSION;
  if (!session) throw new Error("/wt fork needs Rex. This pi does not run inside Rex.");
  if (!branch) throw new Error("Usage: /wt fork <branch>");
  if (tabOf(await rexWindows(session), branch)) throw new Error(`Branch ${branch} already has a Rex tab.`);
  await ctx.waitForIdle();
  const wt = await ensureWorktree(ctx.cwd, branch);
  if (wt.path === (await currentWorktree(ctx.cwd))) throw new Error(`Session is already in ${wt.path}.`);
  const tab = await openWindow(session, wt.path, ["pi", "--session", forkSession(ctx, wt.path)], {
    label: branch,
    focus: false,
  });
  await selectWindow(session, tab.window_id).catch((e) =>
    ctx.ui.notify(`Rex could not switch to the fork: ${errorMessage(e)}`, "warning"),
  );
  ctx.ui.notify(`${createdText(wt)} Forked this session into Rex tab ${branch}.`, "info");
}

async function pickWorktree(ctx: ExtensionCommandContext): Promise<Worktree | undefined> {
  const worktrees = await listWorktrees(ctx.cwd);
  const root = worktrees[0]!.path;
  const here = await currentWorktree(ctx.cwd);
  const choices = new Map(
    worktrees.map((w) => [
      `${w.path === here ? "●" : " "} ${w.branch ?? "(detached)"}  ${relative(root, w.path) || "."}`,
      w,
    ]),
  );
  const label = await ctx.ui.select("Move session to worktree", [...choices.keys()]);
  return label === undefined ? undefined : choices.get(label);
}

const reply = (text: string, structuredContent: ToolData, terminate = false) => ({
  content: [{ type: "text" as const, text }],
  details: undefined,
  structuredContent,
  terminate,
});

function createdText(wt: CreatedWorktree): string {
  if (!wt.created) return `Found worktree ${wt.path} on branch ${wt.branch}.`;
  const copied = wt.copied.length ? ` Copied ${wt.copied.join(", ")} from the main checkout.` : "";
  return `Created worktree ${wt.path} on branch ${wt.branch}.${copied}`;
}

export default function (pi: ExtensionAPI) {
  let pendingMove: PendingMove | undefined;

  pi.on("session_start", async (_event, ctx) => {
    // Pi keeps its launch directory when a session moves, and Rex reads the process directory for new panes.
    if (existsSync(ctx.cwd)) process.chdir(ctx.cwd);
  });

  pi.on("agent_settled", (event, ctx) => {
    if (!pendingMove) return;
    if (event.aborted) {
      ctx.ui.notify(`Worktree move cancelled. Run /wt ${pendingMove.commandArgs} to move.`, "warning");
      pendingMove = undefined;
      return;
    }
    pi.sendUserMessage(`/wt ${pendingMove.commandArgs}`, {
      expandPromptTemplates: true,
    });
  });

  pi.registerCommand("wt", {
    description:
      "Move this session to a branch's worktree under .worktrees/, /wt fork <branch> to fork it there in a new Rex tab, or /wt done to remove a clean worktree and move back",
    getArgumentCompletions: async (prefix) => {
      const r = await run(
        "git",
        ["for-each-ref", "--format=%(refname:short)", "refs/heads"],
        undefined,
        process.cwd(),
        5_000,
      );
      if (r.code !== 0) return null;
      const done = {
        value: "done",
        label: "done",
        description: "Remove this clean worktree, keep its branch, move back to the main checkout",
      };
      const fork = {
        value: "fork ",
        label: "fork",
        description: "Fork this session into a branch's worktree in a new Rex tab",
      };
      const forking = prefix.startsWith("fork ");
      const branches = r.stdout
        .split("\n")
        .filter(Boolean)
        .map((b) => ({ value: forking ? `fork ${b}` : b, label: b }));
      return fuzzyFilter(forking ? branches : [done, fork, ...branches], prefix, (item) => item.value);
    },
    handler: async (args, ctx) => {
      const commandArgs = args.trim();
      const continuation = pendingMove?.commandArgs === commandArgs ? pendingMove.continuation : undefined;
      pendingMove = undefined;
      if (!commandArgs && !ctx.hasUI) {
        ctx.ui.notify("Usage: /wt <branch>, /wt fork <branch>, or /wt done", "error");
        return;
      }
      try {
        if (commandArgs === "done") {
          await finishWorktree(ctx, continuation);
          return;
        }
        if (commandArgs === "fork" || commandArgs.startsWith("fork ")) {
          await forkToWorktree(ctx, commandArgs.slice(4).trim());
          return;
        }
        const target = commandArgs ? await ensureWorktree(ctx.cwd, commandArgs) : await pickWorktree(ctx);
        if (!target) return;
        if (target.path === (await currentWorktree(ctx.cwd))) {
          ctx.ui.notify(`Session is already in ${target.path}`, "info");
          return;
        }
        await ctx.waitForIdle();
        await switchToSession(ctx, forkSession(ctx, target.path), `Session moved to ${target.path}`, continuation);
      } catch (e) {
        ctx.ui.notify(errorMessage(e), "error");
      }
    },
  });

  pi.registerTool({
    name: TOOL_NAME,
    label: "Worktree",
    defaultActive: true,
    annotations: {
      readOnlyHint: false,
      destructiveHint: true,
      idempotentHint: false,
      openWorldHint: false,
    },
    description:
      "Git worktrees of this repo, under `.worktrees/`. `list` shows each worktree with its branch, changed files, commits ahead and behind the main checkout, and open Rex tab. Use the other actions when the user asks for them or when the repo's AGENTS.md or plan says to. `enter` moves this session into the worktree of `branch`, creating it if missing; end your turn after it. `spawn` starts a separate agent on `task` in the worktree of `branch`, in a background Rex tab, and this session keeps working. `done` removes the current clean worktree, keeps its branch, and returns to the main checkout; end your turn after it. `remove` deletes the clean worktree of another `branch`, keeps the branch, and closes its Rex tab. Use instead of `git worktree` or `wt`.",
    parameters: Type.Object({
      action: Type.Enum(["list", "enter", "spawn", "done", "remove"]),
      branch: Type.Optional(
        Type.String({
          description: "Required for enter, spawn, and remove, e.g. feat/login",
        }),
      ),
      base: Type.Optional(
        Type.String({
          description: "Start point when enter or spawn creates a new branch. Default: the main checkout's HEAD",
        }),
      ),
      task: Type.Optional(
        Type.String({
          description: "Required for spawn: the full prompt for the new agent, which starts with no context",
        }),
      ),
    }),
    outputSchema: Type.Object({
      worktrees: Type.Optional(
        Type.Array(
          Type.Object({
            branch: Type.Union([Type.String(), Type.Null()]),
            path: Type.String(),
            main: Type.Boolean(),
            changes: Type.Union([Type.Number(), Type.Null()], {
              description: "Changed files, or null when the path is missing",
            }),
            ahead: Type.Union([Type.Number(), Type.Null()]),
            behind: Type.Union([Type.Number(), Type.Null()]),
            tab: Type.Union([Type.String(), Type.Null()], {
              description: "Rex window ID of the branch's tab",
            }),
          }),
        ),
      ),
      path: Type.Optional(Type.String()),
      branch: Type.Optional(Type.String()),
      window_id: Type.Optional(Type.String()),
      block_id: Type.Optional(Type.String()),
    }),
    async execute(_id, { action, branch, base, task }, signal, _onUpdate, ctx) {
      const session = process.env.REX_SESSION;

      if (action === "list") {
        const worktrees = await describeWorktrees(ctx.cwd, signal);
        return reply(formatWorktrees(worktrees), { worktrees });
      }

      if (action === "done") {
        const wt = await finishableWorktree(ctx.cwd, signal);
        pendingMove = {
          commandArgs: "done",
          continuation: `This session finished the worktree of branch \`${wt.branch}\` and moved back to the main checkout at \`${wt.root}\`. The worktree is removed and the branch is kept. Continue the task there.`,
        };
        return reply(
          `The worktree at ${wt.path} is clean. When this turn ends, it is removed, branch ${wt.branch} is kept, and the session moves to ${wt.root}.`,
          { path: wt.root, branch: wt.branch },
          true,
        );
      }

      if (!branch) throw new Error(`Pass \`branch\` to ${action}.`);

      if (action === "remove") {
        const worktrees = await listWorktrees(ctx.cwd, signal);
        const root = worktrees[0]!.path;
        const worktree = worktrees.find((w) => w.branch === branch);
        if (!worktree) throw new Error(`No worktree has branch ${branch}.`);
        if (worktree.path === root) throw new Error(`Branch ${branch} is in the main checkout.`);
        if (worktree.path === (await currentWorktree(ctx.cwd, signal)))
          throw new Error("This session is in that worktree. Use `done` instead.");
        await assertRemovable(worktree, signal);
        await removeWorktree(root, worktree.path, signal);
        let tabNote = "";
        if (session) {
          try {
            const tab = tabOf(await rexWindows(session, signal), branch);
            if (tab) {
              await rex(["window", "close", "-s", session, tab.window_id], signal);
              tabNote = " Closed its Rex tab.";
            }
          } catch {
            tabNote = " Could not close its Rex tab.";
          }
        }
        return reply(`Removed worktree ${worktree.path}. Branch ${branch} is kept.${tabNote}`, {
          path: worktree.path,
          branch,
        });
      }

      if (action === "spawn") {
        if (!session) throw new Error("spawn needs Rex. This pi does not run inside Rex.");
        if (!task) throw new Error("Pass `task` to spawn.");
        const open = tabOf(await rexWindows(session, signal), branch);
        if (open)
          throw new Error(
            `Branch ${branch} already has a Rex tab, block ${firstBlock(open)}. Send the task to that agent instead.`,
          );
        const wt = await ensureWorktree(ctx.cwd, branch, base, signal);
        if (wt.path === wt.root) throw new Error(`Branch ${branch} is in the main checkout. Spawn on another branch.`);
        const tab = await openWindow(
          session,
          wt.path,
          ["pi", "--", task.startsWith("@") ? ` ${task}` : task],
          { label: branch, focus: false },
          signal,
        );
        return reply(
          `${createdText(wt)} An agent started on the task in background Rex tab ${branch}, block ${tab.block_id}.`,
          { path: wt.path, branch, ...tab },
        );
      }

      const wt = await ensureWorktree(ctx.cwd, branch, base, signal);
      if (wt.path === (await currentWorktree(ctx.cwd, signal)))
        return reply(`Session is already in ${wt.path}.`, {
          path: wt.path,
          branch,
        });
      pendingMove = {
        commandArgs: branch,
        continuation: `This session moved to the worktree at \`${wt.path}\` on branch \`${branch}\`. Continue the task there.`,
      };
      return reply(`${createdText(wt)} When this turn ends, the session moves there.`, { path: wt.path, branch }, true);
    },
  });
}
