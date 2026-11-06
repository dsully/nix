import { execFile, spawn } from "node:child_process";
import { setTimeout as sleep } from "node:timers/promises";
import { promisify } from "node:util";

const run = promisify(execFile);
const POLL_MS = 1000;
// A capture holds up to the terminal's ~64 MiB of scrollback
const MAX_CAPTURE = 128 * 1024 * 1024;

export const rexSession = (): string | undefined => process.env.REX_SESSION || undefined;

/** The lines of a capture after the first `sent`, plus the last one sent again if it has been redrawn since, like a progress bar. */
export function newLines(capture: string, sent: number, last?: string): { text: string; sent: number; last?: string } {
  const body = capture.replace(/\n+$/, "");
  const lines = body ? body.split("\n") : [];
  // shortcut: once scrollback drops its oldest lines, the indices shift and that many new lines are skipped; stream the block if that matters
  const from = sent > 0 && sent <= lines.length && lines[sent - 1] !== last ? sent - 1 : sent;
  if (from >= lines.length) return { text: "", sent, last };
  return {
    text: lines
      .slice(from)
      .map((line) => `${line}\n`)
      .join(""),
    sent: lines.length,
    last: lines.at(-1),
  };
}

/** Runs command in a new, unfocused Rex tab named `title`, passing its output on by polling `rex capture`. */
export async function runInTab(
  session: string,
  command: string,
  cwd: string,
  title: string,
  signal: AbortSignal,
  onData: (d: Buffer) => void,
): Promise<{ exitCode: number | null }> {
  const created = await run("rex", [
    "window",
    "new",
    "-s",
    session,
    title,
    "-c",
    cwd,
    "--keep-open",
    "--focus=false",
    "--json",
    "--",
    "bash",
    "-c",
    command,
  ]);
  const block: string = JSON.parse(created.stdout).block_ids[0];
  let sent = 0;
  let last: string | undefined;
  let polled = Promise.resolve();
  // Chained, so a kill's capture and the timer's never pass the same lines on twice
  const poll = () =>
    (polled = polled
      .then(async () => {
        const { stdout } = await run("rex", ["capture", "-s", session, "-b", block, "--trim", "--unwrap"], {
          maxBuffer: MAX_CAPTURE,
        });
        const next = newLines(stdout, sent, last);
        ({ sent, last } = next);
        if (next.text) onData(Buffer.from(next.text));
      })
      .catch(() => {}));
  // The output up to the kill still reaches the log
  const close = () => void poll().then(() => execFile("rex", ["block", "close", "-s", session, block], () => {}));
  if (signal.aborted) close();
  signal.addEventListener("abort", close, { once: true });
  let ended = false;
  const polling = (async () => {
    while (!ended) {
      await sleep(POLL_MS);
      if (!ended) await poll();
    }
  })();

  // rex wait prints {"exit_code": N} when the command exits, or only the block id when the tab closes first
  const result = await new Promise<{ exit_code?: number }>((resolve) => {
    let out = "";
    const wait = spawn("rex", ["wait", "-s", session, block, "--json"], { stdio: ["ignore", "pipe", "ignore"] });
    wait.stdout.on("data", (d) => (out += d));
    wait.on("close", () => {
      try {
        resolve(JSON.parse(out));
      } catch {
        resolve({});
      }
    });
  });
  ended = true;
  await polling;
  signal.removeEventListener("abort", close);
  if (signal.aborted) throw new Error(`closed Rex tab ${title}`);
  if (result.exit_code === undefined) throw new Error(`Rex tab ${title} closed before its command exited`);
  await poll();
  return { exitCode: result.exit_code };
}
