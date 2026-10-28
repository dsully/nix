import { basename } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const PI_TITLE = "\x1b]0;Pi-Bolt - ";
const g = globalThis as typeof globalThis & { __terminalTitleDir?: string };

// pi rewrites "Pi-Bolt - [session - ]<dir>" via a bare stdout write at startup, reload, and every rename, with no setting to disable it.
function patchStdout(): void {
  if (g.__terminalTitleDir !== undefined) return;
  g.__terminalTitleDir = basename(process.cwd());
  const write = process.stdout.write.bind(process.stdout) as (...args: unknown[]) => boolean;
  process.stdout.write = ((chunk: unknown, ...rest: unknown[]) =>
    write(
      typeof chunk === "string" && chunk.startsWith(PI_TITLE) ? `\x1b]0;${g.__terminalTitleDir}\x07` : chunk,
      ...rest,
    )) as typeof process.stdout.write;
}

export default function (pi: ExtensionAPI) {
  patchStdout();
  pi.on("session_start", async (_event, ctx) => {
    g.__terminalTitleDir = basename(ctx.cwd);
  });
}
