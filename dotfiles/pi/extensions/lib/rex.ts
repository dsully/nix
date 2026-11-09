import { run } from "./exec";

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
