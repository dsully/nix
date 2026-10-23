import { mkdir, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { preview } from "./compact.js";

const READ_DEFAULT_LIMIT = 120;
const OUTPUT_DIR = ".pi/quiet-tools/outputs";

const safe = (s: string) => s.replace(/[^\w.-]+/g, "-");

/**
 * Sends the model a head/tail preview of large tool results while the session and UI keep the full output.
 * Previews are rebuilt on every request, so they must be deterministic or the prompt cache breaks.
 */
export default function quietTools(pi: ExtensionAPI) {
  const saved = new Map<string, string>();

  // Pages unbounded reads instead of letting them hit the preview cut; nested (codemode) reads filter whole files.
  pi.on("tool_call", async (event) => {
    if (event.toolName !== "read" || event.parentToolCallId) return;
    const input = event.input as { limit?: number };
    if (input.limit === undefined) input.limit = READ_DEFAULT_LIMIT;
  });

  pi.on("context", async (event, ctx) => {
    const sessionId = ctx.sessionManager.getSessionId();
    for (const message of event.messages) {
      if (message.role !== "toolResult") continue;
      const text = message.content.flatMap((part) => (part.type === "text" ? [part.text] : [])).join("\n");
      const cut = preview(text, message.isError);
      if (cut === undefined) continue;

      const key = `${sessionId}/${message.toolCallId}`;
      let path = saved.get(key);
      if (!path) {
        path = resolve(ctx.cwd, OUTPUT_DIR, safe(sessionId), `${safe(message.toolCallId)}.txt`);
        try {
          await mkdir(dirname(path), { recursive: true });
          await writeFile(path, text, "utf8");
        } catch {
          continue; // fail open: without a saved copy the omitted part would be unrecoverable
        }
        saved.set(key, path);
      }

      const notice = `[quiet-tools] Output cut to its start and end (${text.split("\n").length} lines, ${text.length} chars). Full output: ${path} (read it with offset/limit if the omitted part matters).`;
      message.content = [
        ...message.content.filter((part) => part.type !== "text"),
        { type: "text", text: `${notice}\n\n${cut}` },
      ];
    }
    return { messages: event.messages };
  });
}
