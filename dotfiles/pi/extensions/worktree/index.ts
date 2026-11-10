import { copyFileSync, existsSync, readdirSync, rmdirSync, writeFileSync } from "node:fs";
import { join, relative } from "node:path";
import { Box, fuzzyFilter, Loader, Text } from "@earendil-works/pi-tui";
import {
  SessionManager,
  type ExtensionAPI,
  type ExtensionCommandContext,
  type ExtensionContext,
  type Theme,
} from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { run } from "../lib/exec";
import { errorMessage } from "../lib/error";
import { gitRoot } from "../lib/git-root";
import { textOf } from "../lib/text";
import { openWindow, rex, selectWindow } from "../lib/rex";
import { isUsable, parseWorktreeList, recoveryTarget, takeSnapshot, type Snapshot, type Worktree } from "./recovery";

const WORKTREE_DIR = ".worktrees";
const TOOL_NAME = "worktree";
const LOCAL_CONFIG = /^\.env(\.[^/]+)?$/;
const RESULT_ENTRY = "worktree-result";
const MOVE_MESSAGE = "worktree";
const PROGRESS_WIDGET = "worktree-progress";
const MARKERS = { working: "🤖", waiting: "💬" };

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
  return parseWorktreeList(await git(cwd, ["worktree", "list", "--porcelain"], signal));
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

function writeEmptySession(cwd: string, sessionDir?: string): string {
  const session = SessionManager.create(cwd, sessionDir);
  const file = session.getSessionFile();
  if (!file) throw new Error("pi created no session file");
  writeFileSync(file, `${JSON.stringify(session.getHeader())}\n`, {
    flag: "wx",
  });
  return file;
}

/** A custom session dir (--session-dir or settings) carries over; the default dir is per cwd, so the target gets its own. */
function targetSessionDir(ctx: ExtensionCommandContext): string | undefined {
  const manager = ctx.sessionManager as typeof ctx.sessionManager & { usesDefaultSessionDir?: () => boolean };
  return manager.usesDefaultSessionDir?.() === false ? manager.getSessionDir() : undefined;
}

function forkSession(ctx: ExtensionCommandContext, target: string): string {
  const source = ctx.sessionManager.getSessionFile();
  if (!source) throw new Error("This session is not saved to disk, so it cannot move.");
  const sessionDir = targetSessionDir(ctx);
  const sessionFile = existsSync(source)
    ? SessionManager.forkFrom(source, target, sessionDir).getSessionFile()
    : writeEmptySession(target, sessionDir);
  if (!sessionFile) throw new Error("pi created no session file");
  return sessionFile;
}

interface CommandResult {
  args: string;
  text: string;
  isError: boolean;
}

interface CommandUi {
  /** Spinner above the editor: outside agent turns nothing else shows that `wt` hooks are still running. */
  progress(label: string): void;
  done(): void;
  report(text: string, isError?: boolean): void;
}

function commandUi(pi: ExtensionAPI, ctx: ExtensionContext, args: string): CommandUi {
  const tui = ctx.mode === "tui" && ctx.hasUI;
  let shown: string | undefined;
  return {
    progress(label) {
      if (!tui || shown === label) return;
      shown = label;
      ctx.ui.setWidget(PROGRESS_WIDGET, (ui, theme) => {
        const loader = new Loader(
          ui,
          (s) => theme.fg("accent", s),
          (s) => theme.fg("muted", s),
          label,
        );
        return Object.assign(loader, { dispose: () => loader.stop() });
      });
    },
    done() {
      if (shown === undefined) return;
      shown = undefined;
      ctx.ui.setWidget(PROGRESS_WIDGET, undefined);
    },
    report(text, isError = false) {
      if (tui) pi.appendEntry<CommandResult>(RESULT_ENTRY, { args, text, isError });
      else ctx.ui.notify(text, isError ? "error" : "info");
    },
  };
}

function card(theme: Theme, title: string, text: string, isError: boolean): Box {
  const box = new Box(1, 1, (s) => theme.bg(isError ? "toolErrorBg" : "toolSuccessBg", s));
  const header = theme.fg("toolTitle", theme.bold("Worktree"));
  box.addChild(new Text(title ? `${header} ${theme.fg("accent", title)}` : header, 0, 0));
  box.addChild(new Text(theme.fg(isError ? "error" : "toolOutput", text), 0, 0));
  return box;
}

/** The destination session shows the move; the message also tells the model its directory changed. */
async function switchToSession(
  ctx: ExtensionCommandContext,
  ui: CommandUi,
  sessionFile: string,
  notice: string,
  continuation?: string,
): Promise<void> {
  ui.done();
  await ctx.switchSession(sessionFile, {
    withSession: async (next) => {
      await next.sendMessage(
        { customType: MOVE_MESSAGE, content: continuation ?? notice, display: true },
        { triggerTurn: continuation !== undefined },
      );
    },
  });
}

async function finishWorktree(ctx: ExtensionCommandContext, ui: CommandUi, continuation?: string): Promise<void> {
  await ctx.waitForIdle();
  const { root, path, branch } = await finishableWorktree(ctx.cwd);
  const sessionFile = forkSession(ctx, root);
  ui.progress(`Removing worktree ${path}`);
  await removeWorktree(root, path);
  await clearTabLabel(branch).catch(() => {});
  await switchToSession(
    ctx,
    ui,
    sessionFile,
    `Removed worktree ${path}. Branch ${branch} is kept. Session moved to ${root}.`,
    continuation,
  );
}

async function forkToWorktree(ctx: ExtensionCommandContext, ui: CommandUi, branch: string): Promise<void> {
  const session = process.env.REX_SESSION;
  if (!session) throw new Error("/wt fork needs Rex. This pi does not run inside Rex.");
  if (!branch) throw new Error("Usage: /wt fork <branch>");
  if (tabOf(await rexWindows(session), branch)) throw new Error(`Branch ${branch} already has a Rex tab.`);
  await ctx.waitForIdle();
  ui.progress(`Preparing worktree ${branch}`);
  const wt = await ensureWorktree(ctx.cwd, branch);
  if (wt.path === (await currentWorktree(ctx.cwd))) throw new Error(`Session is already in ${wt.path}.`);
  const tab = await openWindow(session, wt.path, ["pi", "--session", forkSession(ctx, wt.path)], {
    label: branch,
    focus: false,
  });
  const focus = await selectWindow(session, tab.window_id).then(
    () => "",
    (e) => ` Rex could not switch to it: ${errorMessage(e)}`,
  );
  ui.done();
  ui.report(`${createdText(wt)} Forked this session into Rex tab ${branch}.${focus}`);
}

async function recover(
  ctx: ExtensionCommandContext,
  ui: CommandUi,
  snapshot: Snapshot | undefined,
  commandArgs: string,
  continuation?: string,
): Promise<void> {
  const gone = ctx.cwd;
  const skipped = commandArgs ? ` /wt ${commandArgs} did not run.` : "";
  const target = snapshot?.cwd === gone ? await recoveryTarget(snapshot) : undefined;
  if (!target)
    throw new Error(
      `${gone} is no longer a usable worktree, and no other worktree of this repository survives.${skipped} Restart pi in a surviving worktree.`,
    );
  await ctx.waitForIdle();
  ui.progress(`Recovering session to ${target.path}`);
  await switchToSession(
    ctx,
    ui,
    forkSession(ctx, target.path),
    `Session recovered to ${target.path}, because ${gone} is no longer a usable worktree.${skipped}`,
    continuation,
  );
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
  let snapshot: Snapshot | undefined;
  let marked: { root: string; branch: string } | undefined;
  let markerQueue = Promise.resolve();

  // Explicit --branch from the main checkout: the session's worktree may already be removed when it shuts down.
  const setMarker = (value?: string): Promise<void> => {
    const target = marked;
    if (!target) return markerQueue;
    const args = ["config", "state", "marker", ...(value ? ["set", value] : ["clear"]), "--branch", target.branch];
    markerQueue = markerQueue.then(async () => {
      await run("wt", args, undefined, target.root, 5_000);
    });
    return markerQueue;
  };

  pi.registerEntryRenderer<CommandResult>(RESULT_ENTRY, (entry, _options, theme) =>
    entry.data ? card(theme, entry.data.args, entry.data.text, entry.data.isError) : undefined,
  );
  pi.registerMessageRenderer(MOVE_MESSAGE, (message, _options, theme) =>
    card(theme, "", textOf(message.content, "\n"), false),
  );

  pi.on("session_start", async (_event, ctx) => {
    // Pi keeps its launch directory when a session moves, and Rex reads the process directory for new panes.
    if (existsSync(ctx.cwd)) process.chdir(ctx.cwd);
    const next = await takeSnapshot(ctx.cwd);
    if (next || snapshot?.cwd !== ctx.cwd) snapshot = next;
    const root = snapshot?.worktrees[0]?.path;
    marked = ctx.hasUI && root && snapshot?.branch ? { root, branch: snapshot.branch } : undefined;
    void setMarker(MARKERS.waiting);
  });

  pi.on("agent_start", () => setMarker(MARKERS.working));
  pi.on("agent_end", () => setMarker(MARKERS.waiting));
  pi.on("session_shutdown", () => setMarker(undefined));

  pi.on("before_agent_start", (_event, ctx) => {
    const active = pi.getActiveTools();
    const wanted = gitRoot(ctx.cwd) !== undefined || snapshot?.cwd === ctx.cwd;
    if (wanted === active.includes(TOOL_NAME)) return;
    pi.setActiveTools(wanted ? [...active, TOOL_NAME] : active.filter((name) => name !== TOOL_NAME));
  });

  pi.on("agent_settled", (event, ctx) => {
    if (!pendingMove) return;
    const command = `/wt ${pendingMove.commandArgs}`.trimEnd();
    if (event.aborted) {
      ctx.ui.notify(`Worktree move cancelled. Run ${command} to move.`, "warning");
      pendingMove = undefined;
      return;
    }
    pi.sendUserMessage(command, {
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
      const ui = commandUi(pi, ctx, commandArgs);
      try {
        if (!(await isUsable(ctx.cwd, snapshot))) {
          await recover(ctx, ui, snapshot, commandArgs, continuation);
          return;
        }
        if (!commandArgs && !ctx.hasUI) throw new Error("Usage: /wt <branch>, /wt fork <branch>, or /wt done");
        if (commandArgs === "done") {
          await finishWorktree(ctx, ui, continuation);
          return;
        }
        if (commandArgs === "fork" || commandArgs.startsWith("fork ")) {
          await forkToWorktree(ctx, ui, commandArgs.slice(4).trim());
          return;
        }
        let target: Worktree | CreatedWorktree | undefined;
        if (commandArgs) {
          ui.progress(`Preparing worktree ${commandArgs}`);
          target = await ensureWorktree(ctx.cwd, commandArgs);
          ui.done();
        } else target = await pickWorktree(ctx);
        if (!target) return;
        if (target.path === (await currentWorktree(ctx.cwd))) {
          ui.report(`Session is already in ${target.path}.`);
          return;
        }
        await ctx.waitForIdle();
        const created = "created" in target ? `${createdText(target)} ` : "";
        await switchToSession(
          ctx,
          ui,
          forkSession(ctx, target.path),
          `${created}Session moved to ${target.path}.`,
          continuation,
        );
      } catch (e) {
        ui.done();
        ui.report(errorMessage(e), true);
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
      "Git worktrees of this repo, under `.worktrees/`. Use it when the user, the repo's AGENTS.md or a plan asks for worktrees, instead of `git worktree` or `wt`.",
    parameters: Type.Object({
      action: Type.Enum(["list", "enter", "spawn", "done", "remove"], {
        description:
          "list: worktrees with branch, changed files, commits ahead/behind main, Rex tab. enter: move this session into branch's worktree, creating it if missing; end your turn after. spawn: start a separate agent on task in branch's worktree, in a background Rex tab. done: remove the current clean worktree, keep its branch, return to main; end your turn after. remove: delete another branch's clean worktree, keep the branch, close its Rex tab.",
      }),
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

      if (!(await isUsable(ctx.cwd, snapshot))) {
        const target = snapshot?.cwd === ctx.cwd ? await recoveryTarget(snapshot) : undefined;
        if (!target)
          throw new Error(
            `${ctx.cwd} is no longer a usable worktree, and no other worktree of this repository survives. Ask the user to restart pi in a surviving worktree.`,
          );
        pendingMove = {
          commandArgs: "",
          continuation: `This session recovered to the worktree at \`${target.path}\`, because \`${ctx.cwd}\` is no longer a usable worktree. The \`${action}\` action did not run. Decide there whether it is still needed.`,
        };
        return reply(
          `${ctx.cwd} is no longer a usable worktree. The ${action} action did not run. When this turn ends, the session recovers to ${target.path}.`,
          { path: target.path, branch: target.branch },
          true,
        );
      }

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
