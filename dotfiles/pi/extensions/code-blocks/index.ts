import { createHash } from "node:crypto";
import { copyToClipboard, type ExtensionAPI, type ExtensionContext } from "@earendil-works/pi-coding-agent";
import { getCapabilities, Markdown, type TUI } from "@earendil-works/pi-tui";
import { errorMessage } from "../lib/error";
import { patchMethod } from "../lib/patch";

// Pi's Markdown emits OSC 8 only for http(s), mailto and file links; .invalid never resolves (RFC 2606).
const COPY_LINK = "https://pi-code-block.invalid/";
const COPY_LABEL = "📋 copy";
const LINK_ROUTER = Symbol.for("pi.code-blocks.linkRouter");
const COPY_SPAN =
  /\x1b\]8;;https:\/\/pi-code-block\.invalid\/[^\x07\x1b]*(?:\x07|\x1b\\)[^]*?\x1b\]8;;(?:\x07|\x1b\\)/g;
const UNDERLINE = "\x1b[4m";

type Render = (this: Markdown, width: number) => string[];

// Pi underlines every Markdown link and strips escape codes from Markdown text, so the underline goes after rendering.
const installNoUnderline = () => {
  const done = new WeakSet<string[]>();
  patchMethod<Render>(
    Markdown.prototype,
    "render",
    "pi-code-blocks.render",
    (original) =>
      original &&
      function (this: Markdown, width: number) {
        const lines = original.call(this, width);
        if (done.has(lines)) return lines;
        done.add(lines);
        for (let i = 0; i < lines.length; i++)
          if (lines[i].includes(COPY_LINK))
            lines[i] = lines[i].replace(COPY_SPAN, (span) => span.replaceAll(UNDERLINE, ""));
        return lines;
      },
  );
};

interface LinkRouterHost {
  openUrl?: (url: string) => void;
  [LINK_ROUTER]?: { emit: (url: string) => void };
}

type Fence = { indent: string; lang: string; code: string; end: number };

const closedFences = (lines: readonly string[]): Fence[] => {
  const fences: Fence[] = [];
  let i = 0;
  while (i < lines.length) {
    const open = /^( *)(`{3,}|~{3,})(.*)$/.exec(lines[i]);
    if (!open) {
      i++;
      continue;
    }
    const [, indent, marker, info] = open;
    const close = new RegExp(`^ *${marker[0]}{${marker.length},}\\s*$`);
    const code: string[] = [];
    let j = i + 1;
    for (; j < lines.length && !close.test(lines[j]); j++) {
      const line = lines[j];
      code.push(line.slice(Math.min(indent.length, line.length - line.trimStart().length)));
    }
    if (j < lines.length)
      fences.push({ indent, lang: info.trim().split(/\s+/)[0] ?? "", code: code.join("\n"), end: j });
    i = j + 1;
  }
  return fences;
};

const keyOf = (code: string): string => createHash("sha1").update(code).digest("hex").slice(0, 10);

export default function codeBlocks(pi: ExtensionAPI) {
  const blocks = new Map<string, string>();
  let currentCtx: ExtensionContext | undefined;
  let linksReady = false;
  installNoUnderline();

  const onLink = (url: string) => {
    const ctx = currentCtx;
    const code = blocks.get(url.slice(COPY_LINK.length));
    if (!ctx) return;
    if (code === undefined) {
      ctx.ui.notify("That code block is no longer on screen", "warning");
      return;
    }
    copyToClipboard(code).then(
      () => ctx.ui.notify("Copied code block", "info"),
      (e) => ctx.ui.notify(errorMessage(e), "error"),
    );
  };

  // Fullscreen pi-tui opens OSC 8 links through the TS-private TuiAltScreen.openUrl, which has no extension hook.
  // The router lives on the TUI object so /reload swaps its handler instead of wrapping openUrl twice.
  const installLinkRouter = (tui: TUI) => {
    const host = tui as unknown as LinkRouterHost;
    const openUrl = host.openUrl;
    if (typeof openUrl !== "function") return;
    const router = host[LINK_ROUTER];
    if (router) router.emit = onLink;
    else {
      const created = { emit: onLink };
      host[LINK_ROUTER] = created;
      host.openUrl = (url) => (url.startsWith(COPY_LINK) ? created.emit(url) : openUrl.call(host, url));
    }
    linksReady = true;
  };

  pi.on("session_start", async (_event, ctx) => {
    currentCtx = ctx;
    blocks.clear();
    if (ctx.mode === "tui")
      ctx.ui.setWidget("code-blocks-links", (tui) => {
        installLinkRouter(tui);
        return { render: () => [], invalidate() {} };
      });
  });

  pi.registerMarkdownTransformer((markdown, context) => {
    if (!linksReady || context.isStreaming || context.messageType !== "assistant" || !getCapabilities().hyperlinks)
      return markdown;
    const lines = markdown.split("\n");
    const fences = closedFences(lines).filter((f) => f.lang.toLowerCase() !== "mermaid" && f.code.trim() !== "");
    if (fences.length === 0) return markdown;
    const out: string[] = [];
    let cursor = 0;
    for (const fence of fences) {
      const key = keyOf(fence.code);
      blocks.set(key, fence.code);
      out.push(...lines.slice(cursor, fence.end + 1), `${fence.indent}[${COPY_LABEL}](${COPY_LINK}${key})`);
      cursor = fence.end + 1;
      if (lines[cursor]?.trim()) out.push("");
    }
    out.push(...lines.slice(cursor));
    return out.join("\n");
  });
}
