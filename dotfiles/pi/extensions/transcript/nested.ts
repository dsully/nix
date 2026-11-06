export function nestedResultLines(text: string, expanded: boolean): string[] {
  const lines = text
    .split("\n")
    .map((line) => line.trimEnd())
    .filter((line) => line.trim());
  if (lines.length === 0) return ["(no result)"];
  const [head, ...rest] = lines;
  const shown = expanded ? rest.slice(0, 30) : rest.slice(0, 3);
  const body = shown.map((line, index) => `${index === 0 ? "  └ " : "    "}${line}`);
  const more = rest.length - shown.length;
  if (more > 0) body.push(`    … ${more} more`);
  return [head ?? "(no result)", ...body];
}

type MixedChild = { native: boolean };

/** Self-rendered rows stay out of the collapsed group so their own nested lines survive. */
export function splitNative<T extends MixedChild>(children: readonly T[]): Array<{ native: T } | { grouped: T[] }> {
  const parts: Array<{ native: T } | { grouped: T[] }> = [];
  let grouped: T[] = [];
  const flush = () => {
    if (grouped.length === 0) return;
    parts.push({ grouped });
    grouped = [];
  };
  for (const child of children) {
    if (child.native) {
      flush();
      parts.push({ native: child });
    } else {
      grouped.push(child);
    }
  }
  flush();
  return parts;
}

type NativeRow = {
  toolName?: string;
  args?: unknown;
  getRenderShell?: () => string;
};

const NATIVE_TOOLS = new Set(["bg_run", "bg_status", "bg_kill"]);

/** Background rows keep the background extension's └ line. Markers owns every other collapsed row, including subagent plans. */
export function keepsNative(row: NativeRow): boolean {
  return NATIVE_TOOLS.has(row.toolName ?? "");
}
