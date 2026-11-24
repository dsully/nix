/**
 * /export-md [path] and /export-html [path]: write the current branch of this session as a readable transcript.
 * Tool calls and thinking fold into collapsible blocks; the HTML is one self-contained file with no scripts.
 * The path defaults to `<session title>.<ext>` in the working directory.
 */

import { existsSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { resolve } from "node:path";
import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import { infoOf, toHtml, toMarkdown, turnsOf } from "./render.js";

type Format = "md" | "html";

export function defaultName(title: string, ext: Format): string {
  const base = title
    .replace(/[/\\:*?"<>|\u0000-\u001f]/g, "-")
    .replace(/\s+/g, " ")
    .trim()
    .slice(0, 80);
  return `${base || "session"}.${ext}`;
}

async function exportSession(format: Format, args: string, ctx: ExtensionCommandContext): Promise<void> {
  const sm = ctx.sessionManager;
  const entries = sm.getBranch();
  const turns = turnsOf(entries);
  const info = infoOf(sm.getHeader(), entries, sm.getSessionName(), turns);

  const arg = args.trim();
  const path = resolve(ctx.cwd, arg ? arg.replace(/^~(?=$|\/)/, homedir()) : defaultName(info.title, format));
  if (existsSync(path) && !(await ctx.ui.confirm("Overwrite?", path))) return;

  writeFileSync(path, format === "md" ? toMarkdown(info, turns) : toHtml(info, turns));
  ctx.ui.notify(`Exported to ${path}`, "info");
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("export-md", {
    description: "Export this session as Markdown: /export-md [path]",
    handler: (args, ctx) => exportSession("md", args, ctx),
  });
  pi.registerCommand("export-html", {
    description: "Export this session as styled HTML: /export-html [path]",
    handler: (args, ctx) => exportSession("html", args, ctx),
  });
}
