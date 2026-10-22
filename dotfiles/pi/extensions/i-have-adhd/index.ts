/**
 * ADHD-shaped replies: next action first, numbered steps, no tangents.
 * Vendored from https://github.com/ayghri/i-have-adhd (MIT, see LICENSE).
 *
 * - /adhd toggles the mode for the current session branch.
 * - `pi --adhd` starts sessions with it on.
 * - "stop adhd mode" or "normal mode" in a prompt turns it off.
 */
import { readFileSync } from "node:fs";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const KEY = "i-have-adhd";
const ENTRY_TYPE = "i-have-adhd-mode";
const STOP = /\b(stop adhd mode|normal mode)\b/i;

const RULES = readFileSync(new URL("./rules.md", import.meta.url), "utf8").trim();
const SECTION = `<i-have-adhd>
ADHD MODE ACTIVE. "stop adhd mode" or "normal mode" turns it off.

${RULES}
</i-have-adhd>`;

type Entry = { type: string; customType?: string; data?: unknown };

function savedMode(entries: Iterable<Entry>): boolean | undefined {
  let on: boolean | undefined;
  for (const entry of entries) {
    if (entry.type !== "custom" || entry.customType !== ENTRY_TYPE) continue;
    const data = entry.data as { on?: unknown } | undefined;
    if (typeof data?.on === "boolean") on = data.on;
  }
  return on;
}

export default function iHaveAdhd(pi: ExtensionAPI) {
  let on = false;

  pi.registerFlag("adhd", { description: "Start with ADHD-shaped replies on", type: "boolean", default: false });

  const showStatus = (ctx: ExtensionContext) => {
    if (ctx.hasUI) ctx.ui.setStatus(KEY, on ? ctx.ui.theme.fg("accent", "adhd") : undefined);
  };

  const setMode = (value: boolean, ctx: ExtensionContext) => {
    on = value;
    pi.appendEntry(ENTRY_TYPE, { on });
    showStatus(ctx);
    if (ctx.hasUI) ctx.ui.notify(`ADHD mode ${on ? "on" : "off"}.`, "info");
  };

  const restore = (ctx: ExtensionContext) => {
    on = savedMode(ctx.sessionManager.getBranch()) ?? pi.getFlag("adhd") === true;
    showStatus(ctx);
  };

  pi.registerCommand("adhd", {
    description: "Toggle ADHD-shaped replies (next action first, numbered steps, no tangents)",
    handler: async (_args, ctx) => setMode(!on, ctx),
  });

  pi.on("session_start", async (_event, ctx) => restore(ctx));
  pi.on("session_tree", async (_event, ctx) => restore(ctx));

  pi.on("input", async (event, ctx) => {
    if (on && event.source !== "extension" && STOP.test(event.text)) setMode(false, ctx);
  });

  pi.on("before_agent_start", async (event) => {
    if (on) event.systemPromptOptions.sections[KEY] = SECTION;
    else delete event.systemPromptOptions.sections[KEY];
  });
}
