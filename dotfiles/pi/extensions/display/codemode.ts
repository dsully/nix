// Ported from @pi-kaush/pi-tool-call-markers (MIT, Copyright (c) 2026 Kaushik Gopal), src/index.ts.

type Call = { name?: unknown; args?: unknown };

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

/**
 * The command of a codemode bash call. Pi stores call args as a JSON preview capped at
 * 200 characters, so a long command can end inside a JSON string; only complete escapes
 * are decoded and the cut command keeps an ellipsis.
 */
export function codemodeBashCommand(args: unknown): string | undefined {
  if (typeof args !== "string") return undefined;
  try {
    const parsed: unknown = JSON.parse(args);
    return isRecord(parsed) && typeof parsed.command === "string" ? parsed.command : undefined;
  } catch {
    if (!args.endsWith("...")) return undefined;
    const prefix = args.slice(0, -3);
    const match = /^\{\s*"command"\s*:\s*"((?:[^"\\]|\\(?:["\\/bfnrt]|u[\da-fA-F]{4}))*)/.exec(prefix);
    if (!match) return undefined;
    try {
      const command: unknown = JSON.parse(`"${match[1]}"`);
      const suffix = prefix[match[0].length] === '"' ? "" : "…";
      return typeof command === "string" ? command + suffix : undefined;
    } catch {
      return undefined;
    }
  }
}

function inline(text: string): string {
  return text.replace(/\s+/g, " ").trim();
}

/**
 * What a codemode script called: each tool once with its total count, then each distinct
 * bash command: `bash ×2 git status, bash npm test, read ×3`.
 */
export function codemodeCallsSummary(calls: unknown): string | undefined {
  if (!Array.isArray(calls) || calls.length === 0) return undefined;
  const counts = new Map<string, number>();
  const labels = new Map<string, { name: string; preview: string }>();
  for (const call of calls as Call[]) {
    if (!isRecord(call) || typeof call.name !== "string" || !call.name) continue;
    const command = call.name === "bash" ? codemodeBashCommand(call.args) : undefined;
    const preview = command === undefined ? "" : inline(command);
    counts.set(call.name, (counts.get(call.name) ?? 0) + 1);
    labels.set(preview ? `${call.name} ${preview}` : call.name, { name: call.name, preview });
  }
  if (counts.size === 0) return undefined;
  const shown = new Set<string>();
  return [...labels.values()]
    .map(({ name, preview }) => {
      const heading = shown.has(name) ? name : `${name} ×${counts.get(name) ?? 1}`;
      shown.add(name);
      return preview ? `${heading} ${preview}` : heading;
    })
    .join(", ");
}
