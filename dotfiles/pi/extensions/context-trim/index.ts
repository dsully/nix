import { mkdir, readdir, rm, stat, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { textOf } from "../lib/text.js";
import { preview } from "./compact.js";

const READ_DEFAULT_LIMIT = 120;
const OUTPUT_DIR = join(process.env.XDG_CACHE_HOME || join(homedir(), ".cache"), "pi", "context-trim");
const KEEP_MS = 7 * 24 * 60 * 60 * 1000;

const safe = (s: string) => s.replace(/[^\w.-]+/g, "-");

// shortcut: another pi process idle for KEEP_MS loses its saved outputs; save per request if that ever bites.
async function pruneOutputs(currentSession: string): Promise<void> {
  const cutoff = Date.now() - KEEP_MS;
  for (const name of await readdir(OUTPUT_DIR).catch(() => [])) {
    if (name === currentSession) continue;
    const dir = join(OUTPUT_DIR, name);
    const modified = await stat(dir).then(
      (s) => s.mtimeMs,
      () => Infinity,
    );
    if (modified < cutoff) await rm(dir, { recursive: true, force: true }).catch(() => {});
  }
}

/**
 * Sends the model a head/tail preview of large tool results while the session and UI keep the full output.
 * Previews are rebuilt on every request, so they must be deterministic or the prompt cache breaks.
 */
export default function contextTrim(pi: ExtensionAPI) {
  const saved = new Map<string, string>();

  pi.on("session_start", (_event, ctx) => {
    void pruneOutputs(safe(ctx.sessionManager.getSessionId()));
  });

  pi.on("tool_call", async (event) => {
    if (event.toolName !== "read" || event.parentToolCallId) return;
    const input = event.input as { limit?: number };
    if (input.limit === undefined) input.limit = READ_DEFAULT_LIMIT;
  });

  pi.on("context", async (event, ctx) => {
    const sessionId = ctx.sessionManager.getSessionId();
    for (const message of event.messages) {
      if (message.role !== "toolResult") continue;
      const text = textOf(message.content);
      const cut = preview(text, message.isError);
      if (cut === undefined) continue;

      const key = `${sessionId}/${message.toolCallId}`;
      let path = saved.get(key);
      if (!path) {
        path = join(OUTPUT_DIR, safe(sessionId), `${safe(message.toolCallId)}.txt`);
        try {
          await mkdir(dirname(path), { recursive: true });
          await writeFile(path, text, "utf8");
        } catch {
          // Fail open so an omitted output is never lost when saving fails.
          continue;
        }
        saved.set(key, path);
      }

      const notice = `[context-trim] Output cut to its start and end (${text.split("\n").length} lines, ${text.length} chars). Full output: ${path} (read it with offset/limit if the omitted part matters).`;
      message.content = [
        ...message.content.filter((part) => part.type !== "text"),
        { type: "text", text: `${notice}\n\n${cut}` },
      ];
    }
    return { messages: event.messages };
  });
}
