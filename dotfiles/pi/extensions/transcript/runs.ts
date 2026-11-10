import { isHarmlessRedirect, parseShell, writesOrRuns } from "./shell.js";

export type LookKind = "read" | "search" | "list";

// From pi-compact-tools' Claude style: a command made only of these only looks around.
const SEARCH_COMMANDS = new Set(["find", "fd", "grep", "rg", "ag", "ack", "locate", "which", "whereis"]);
const READ_COMMANDS = new Set([
  "cat",
  "bat",
  "head",
  "tail",
  "less",
  "more",
  "wc",
  "stat",
  "file",
  "strings",
  "jq",
  "awk",
  "cut",
  "sort",
  "uniq",
  "tr",
]);
const LIST_COMMANDS = new Set(["ls", "eza", "tree", "du"]);
const NEUTRAL_COMMANDS = new Set(["echo", "printf", "true", "false", ":", "cd", "pwd"]);
const GIT_READS = new Set(["status", "log", "diff", "show", "blame", "ls-files", "rev-parse", "grep"]);

function gitKind(words: readonly string[]): LookKind | undefined {
  const sub = words[1];
  if (!sub || !GIT_READS.has(sub)) return undefined;
  return sub === "grep" ? "search" : sub === "ls-files" ? "list" : "read";
}

/** How a shell command looks around, if that is all it does; undefined for anything that writes or runs. */
export function classifyShell(command: string): LookKind | undefined {
  const parsed = parseShell(command.replace(/\r\n?/g, "\n"));
  if (!parsed || parsed.opaque) return undefined;
  const seen = new Set<LookKind>();
  for (const { words, redirects } of parsed.commands) {
    if (!redirects.every(isHarmlessRedirect) || writesOrRuns(words)) return undefined;
    const program = words[0];
    if (!program || NEUTRAL_COMMANDS.has(program)) continue;
    const kind =
      program === "git"
        ? gitKind(words)
        : SEARCH_COMMANDS.has(program)
          ? "search"
          : READ_COMMANDS.has(program)
            ? "read"
            : LIST_COMMANDS.has(program)
              ? "list"
              : undefined;
    if (!kind) return undefined;
    seen.add(kind);
  }
  return seen.has("list") ? "list" : seen.has("search") ? "search" : seen.has("read") ? "read" : undefined;
}

/** Whether a call only looks around, and how; such calls fold into one run. */
export function lookKind(toolName: string, args: unknown): LookKind | undefined {
  if (toolName === "read") return "read";
  if (toolName === "grep" || toolName === "find" || toolName === "tool_search") return "search";
  if (toolName === "ls") return "list";
  if (toolName !== "bash") return undefined;
  const command = (args as { command?: unknown } | undefined)?.command;
  return typeof command === "string" ? classifyShell(command) : undefined;
}

export type Member = { id: string; kind: LookKind; label: string; done: boolean; error: boolean };
export type Run = { members: Member[]; startedAt: number };

/** Consecutive look-around calls, keyed by tool call id. Visible assistant content, a user turn, or any other tool ends a run. */
export class Runs {
  private byId = new Map<string, Run>();
  private current: Run | undefined;

  get(id: string): Run | undefined {
    return this.byId.get(id);
  }

  end(): void {
    this.current = undefined;
  }

  clear(): void {
    this.byId.clear();
    this.current = undefined;
  }

  add(member: Omit<Member, "done" | "error"> & Partial<Member>, now: number): Run {
    const existing = this.byId.get(member.id);
    if (existing) return existing;
    const run = this.current ?? { members: [], startedAt: now };
    run.members.push({ done: false, error: false, ...member });
    this.byId.set(member.id, run);
    this.current = run;
    return run;
  }

  finish(id: string, error: boolean): Run | undefined {
    const run = this.byId.get(id);
    const member = run?.members.find((m) => m.id === id);
    if (member) Object.assign(member, { done: true, error });
    return run;
  }
}

const VERBS: Record<LookKind, [done: string, running: string, one: string, many: string]> = {
  read: ["read", "reading", "file", "files"],
  search: ["searched", "searching", "pattern", "patterns"],
  list: ["listed", "listing", "directory", "directories"],
};

/** `Read 3 files, searched 2 patterns`, or the running form while any member runs. */
export function runSummary(members: readonly Member[], running: boolean): string {
  const counts = new Map<LookKind, number>();
  for (const member of members) counts.set(member.kind, (counts.get(member.kind) ?? 0) + 1);
  const text = [...counts]
    .map(([kind, count]) => {
      const [done, active, one, many] = VERBS[kind];
      return `${running ? active : done} ${count} ${count === 1 ? one : many}`;
    })
    .join(", ");
  return text.charAt(0).toUpperCase() + text.slice(1);
}
