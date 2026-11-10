import { realpathSync } from "node:fs";
import { basename, isAbsolute, resolve } from "node:path";

// Real paths, so a cd through a symlink such as /tmp still counts as cwd
const real = (path: string) => {
  try {
    return realpathSync(path);
  } catch {
    return path;
  }
};

/** A command's first line in at most max characters, without leading cds into cwd, leading settings, or the script's folder. */
export function shortCommand(command: string, cwd: string, max = Infinity): string {
  let cd = "";
  const shown = command
    .trim()
    .replace(/^(?:cd\s+(?:"[^"]*"|'[^']*'|\S+)[ \t]*(?:&&|;|\n)\s*)+/, (prefix) => {
      const [, quoted, separator] = [...prefix.matchAll(/cd\s+("[^"]*"|'[^']*'|\S+)[ \t]*(&&|;|\n)/g)].at(-1)!;
      const dir = quoted.replace(/^["']|["']$/g, "");
      if (real(resolve(cwd, dir)) !== real(resolve(cwd)))
        cd = `cd ${isAbsolute(dir) ? `…/${basename(dir)}` : quoted}${separator === ";" ? ";" : " &&"} `;
      return "";
    })
    .split("\n")[0]
    // Before the script path below, which would cut a setting at its last /
    .replace(/^(\w+=("[^"]*"|'[^']*'|\S*)\s+)+/, "")
    .replace(/^\S*\/(?=[^\s/]+(\s|$))/, "");
  const line = cd + shown;
  return line.length > max ? `${line.slice(0, max - 1)}…` : line;
}
