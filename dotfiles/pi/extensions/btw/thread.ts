import { join } from "node:path";
import type { SessionEntry } from "@earendil-works/pi-coding-agent";

export const MARKER = "rex-btw";

export interface Thread {
  id: string;
  question: string;
  title: string;
  provider: string;
  model: string;
}

export function readLink(entry: SessionEntry | undefined): Thread | undefined {
  if (entry?.type !== "custom_message" || entry.customType !== MARKER) return;
  const thread = entry.details as Partial<Thread> | undefined;
  if (
    typeof thread?.id === "string" &&
    /^[\da-f-]{36}$/.test(thread.id) &&
    typeof thread.title === "string" &&
    typeof thread.question === "string" &&
    typeof thread.provider === "string" &&
    typeof thread.model === "string"
  )
    return thread as Thread;
}

export function titleFor(question: string) {
  return (
    Array.from(question.replace(/[\p{Cc}\p{Cf}\s]+/gu, " ").trim())
      .slice(0, 80)
      .join("") || "New BTW"
  );
}

/** The child pi's arguments; a resumed thread already has its model and first question. */
export function childArgs(directory: string, thread: Thread, resumed: boolean): string[] {
  const args = [
    "pi",
    "--no-mcp",
    "--models",
    "",
    "--no-skills",
    "--no-prompt-templates",
    "--no-context-files",
    "--tools",
    "read,grep,find,ls",
    "--session-dir",
    directory,
    "--session-id",
    thread.id,
    "--append-system-prompt",
    join(directory, "snapshot.md"),
  ];
  if (resumed) return args;
  args.push("--provider", thread.provider, "--model", thread.model);
  // A leading space keeps pi from treating an @-prefixed question as a file argument
  if (thread.question) args.push("--", ` ${thread.question}`);
  return args;
}
