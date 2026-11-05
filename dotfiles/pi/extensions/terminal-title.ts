import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const PI_TITLE = "\x1b]0;Pi-Bolt - ";
const g = globalThis as typeof globalThis & { __terminalTitlePatched?: boolean };

// pi writes "Pi-Bolt - [session - ]<dir>" via a bare stdout write at startup, reload, and every rename, with no setting to disable it.
function patchStdout(): void {
  if (g.__terminalTitlePatched) return;
  g.__terminalTitlePatched = true;
  const write = process.stdout.write.bind(process.stdout) as (...args: unknown[]) => boolean;
  process.stdout.write = ((chunk: unknown, ...rest: unknown[]) =>
    write(
      typeof chunk === "string" && chunk.startsWith(PI_TITLE) ? `\x1b]0;${chunk.slice(PI_TITLE.length)}` : chunk,
      ...rest,
    )) as typeof process.stdout.write;
}

export default function (_pi: ExtensionAPI) {
  patchStdout();
}
