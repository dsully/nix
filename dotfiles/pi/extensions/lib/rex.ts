import { spawn } from "node:child_process";
import { createInterface } from "node:readline";
import { run } from "./exec";

export const SHELL_FLAVOR = "com.superlogical.terminal.shell";

export type Placement = "float" | "split" | "window";

export const rexDoArgs = (
  script: string,
  args: unknown,
  options: { session?: string; json?: boolean } = {},
): string[] => [
  "do",
  ...(options.session ? ["-s", options.session] : []),
  script,
  ...(options.json ? ["--json"] : []),
  "--args",
  JSON.stringify(args),
];

export async function rex(args: string[], signal?: AbortSignal): Promise<string> {
  const r = await run("rex", args, signal, undefined, 15_000);
  if (r.code !== 0) throw new Error(`rex ${args.slice(0, 2).join(" ")}: ${(r.stderr || r.stdout).trim()}`);
  return r.stdout;
}

export const api = async <T = any>(session: string, method: string, body: object = {}, signal?: AbortSignal) =>
  JSON.parse(
    await rex(["api", "call", "-s", session, method, JSON.stringify({ session_id: session, ...body })], signal),
  ) as T;

/** The Rex pane this pi runs in, or undefined outside Rex. */
export function here(): { session: string; block: string } | undefined {
  const { REX_SESSION: session, REX_BLOCK: block } = process.env;
  return session && block ? { session, block } : undefined;
}

export async function windowOf(session: string, block: string): Promise<string> {
  const { block: info } = await api<{ block: { window_id?: string } }>(session, "session.describe_block", {
    block_id: block,
  });
  if (!info.window_id) throw new Error("The Rex pane is not in a tab.");
  return info.window_id;
}

/**
 * A terminal block running command on pi's PATH, which the user's shell would otherwise rebuild without devshell tools.
 * Not shell "none": Rex then reports exit code 0 for every command.
 */
export const shellLayout = (label: string, command: string[], cwd: string | undefined, keepOpen: boolean) => ({
  block: {
    flavor: SHELL_FLAVOR,
    label,
    options: {
      command: ["env", `PATH=${process.env.PATH ?? ""}`, ...command],
      cwd,
      ...(keepOpen ? { exit: { on_completion: false } } : {}),
    },
  },
});

export interface Pane {
  block_id: string;
  layer_id?: string;
}

/**
 * Opens layout beside the anchor pane: a float in its tab, a split after it (a new tab if the split fails), or a new tab.
 * Floats start minimized unless focus is set.
 */
export async function openPane(
  session: string,
  anchor: string,
  placement: Placement,
  layout: object,
  options: { label: string; bounds?: number[]; focus?: boolean; direction?: "horizontal" | "vertical" },
): Promise<Pane> {
  const focus = options.focus ?? false;
  const created = async () => {
    if (placement === "float") {
      const window_id = await windowOf(session, anchor);
      return api(session, "session.new_layer", {
        window_id,
        bounds: options.bounds ?? [0.1, 0.1, 0.8, 0.6],
        layout,
        focus,
      });
    }
    if (placement === "split") {
      const split = await api(session, "session.new_split", {
        anchor_id: anchor,
        direction: options.direction ?? "vertical",
        side: "after",
        layout,
        focus,
      }).catch(() => undefined);
      if (split) return split;
    }
    return api(session, "session.new_window", { window_label: options.label, layout, focus });
  };
  const r = (await created()) as { block_ids: string[]; layer_id?: string };
  const pane = { block_id: r.block_ids[0]!, layer_id: r.layer_id };
  if (placement === "float" && !focus && pane.layer_id) {
    await setLayerState(session, pane.layer_id, "minimized").catch(() => {});
  }
  return pane;
}

export const setLayerState = (session: string, layerId: string, state: "normal" | "minimized", focus = false) =>
  api(session, "session.set_layer_state", { layer_id: layerId, state, focus });

export const focusBlock = (session: string, block: string) => api(session, "session.focus_block", { block_id: block });

export const closeBlock = (session: string, block: string) => rex(["block", "close", "-s", session, block]);

export const blockExists = (session: string, block: string) =>
  rex(["block", "inspect", "-s", session, block, "--json"]).then(
    () => true,
    () => false,
  );

export async function sendToBlock(session: string, block: string, text?: string, key?: string) {
  if (text) await rex(["send", "-s", session, "-b", block, "--", text]);
  if (key) await rex(["send-key", "-s", session, "-b", block, key]);
}

/** `rex wait --json` prints `{"exit_code":N}` when the command exits; anything else means the pane closed first. */
export function exitCode(stdout: string): number | undefined {
  try {
    const code = JSON.parse(stdout.trim().split("\n")[0]!).exit_code;
    return typeof code === "number" ? code : undefined;
  } catch {
    return undefined;
  }
}

/** Calls onExit with the block's exit code, or undefined if the pane closed first; the returned function stops watching without calling it. */
export function waitForExit(session: string, block: string, onExit: (code: number | undefined) => void): () => void {
  const p = spawn("rex", ["wait", "-s", session, block, "--json"], { stdio: ["ignore", "pipe", "ignore"] });
  let out = "";
  let detached = false;
  p.stdout.setEncoding("utf8").on("data", (d: string) => (out += d));
  p.on("error", () => {});
  p.on("close", () => {
    if (!detached) onExit(exitCode(out));
  });
  return () => {
    detached = true;
    p.kill();
  };
}

/** Streams the session's events to onEvent until the returned function is called. */
export function watchEvents(session: string, onEvent: (event: any) => void): () => void {
  const p = spawn("rex", ["events", "-s", session, "--json"], { stdio: ["ignore", "pipe", "ignore"] });
  p.on("error", () => {});
  createInterface({ input: p.stdout }).on("line", (line) => {
    try {
      const event = JSON.parse(line).payload?.event;
      if (event) onEvent(event);
    } catch {}
  });
  return () => p.kill();
}

export async function openWindow(
  session: string,
  cwd: string,
  command: string[],
  options: { label?: string; focus?: boolean } = {},
  signal?: AbortSignal,
): Promise<{ window_id: string; block_id: string }> {
  const out = await rex(
    [
      "window",
      "new",
      "-s",
      session,
      ...(options.label ? [options.label] : []),
      "-c",
      cwd,
      ...(options.focus === false ? ["--focus=false"] : []),
      "--json",
      "--",
      ...command,
    ],
    signal,
  );
  const created = JSON.parse(out) as { window_id: string; block_ids: string[] };
  return { window_id: created.window_id, block_id: created.block_ids[0]! };
}

// Rex.app ignores the server's active window, so only an app action switches its visible tab: https://discord.com/channels/1546797889009881158/1559289044439932949
export const selectWindow = (session: string, windowId: string, signal?: AbortSignal) =>
  rex(["do", "-s", session, "session.select", `session_id=${session}`, `window_id=${windowId}`], signal);
