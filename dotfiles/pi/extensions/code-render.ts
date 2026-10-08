import {
  copyToClipboard,
  type ExtensionAPI,
  type ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import {
  Markdown,
  stripTerminalSequences,
  visibleWidth,
  wrapTextWithAnsi,
  type TuiMouseEvent,
  type TuiMouseEventResult,
} from "@earendil-works/pi-tui";

const PATCH = Symbol.for("pi-code-render.markdown-patch");
const CARD_BG = "toolSuccessBg" as const;
const COPY_LABEL = "[COPY]";
/**
 * Zero-width prefix on the rendered label: prose or inline code can end with
 * the literal `[COPY]`, and such a row would hijack the anchor search.
 */
const COPY_ANCHOR = `\u200b${COPY_LABEL}`;
const STATUS_KEY = "pi-code-render";
const STATUS_CLEAR_MS = 2000;

/** Left/right padding inside a code card, in terminal columns. */
const CARD_PAD = "  ";

type CodeToken = {
  type?: string;
  lang?: string;
  text?: string;
};

type CopyHit = {
  y: number;
  startX: number;
  endX: number;
  source: string;
};

type LayoutCache = {
  key: string;
  hits: CopyHit[];
  lines: string[];
};

/**
 * `Omit` drops the private members before re-declaring them, so the
 * intersection does not collapse to `never`.
 */
type MarkdownWithPrivateRenderer = Omit<Markdown, "renderToken" | "render" | "handleMouse"> & {
  renderToken: (
    token: CodeToken,
    width: number,
    nextTokenType?: string,
    styleContext?: unknown,
  ) => string[];
  render: (width: number) => string[];
  handleMouse?: (event: TuiMouseEvent) => TuiMouseEventResult | undefined;
};

type PatchRecord = { restore: () => void };

function languageFromInfo(info: unknown): string {
  return typeof info === "string" ? info.trim().split(/\s+/, 1)[0] ?? "" : "";
}

function normalizeCodeToken(token: CodeToken, language: string): CodeToken {
  // Markdown info strings can include metadata (for example, "js workflow").
  return language && token.lang !== language ? { ...token, lang: language } : token;
}

/** Pad a styled line with the card background out to `width` columns. */
function fillRow(text: string, width: number, bg: (value: string) => string): string {
  const clipped =
    visibleWidth(text) <= width ? text : (wrapTextWithAnsi(text, Math.max(1, width))[0] ?? "");
  return bg(clipped + " ".repeat(Math.max(0, width - visibleWidth(clipped))));
}

/** Find each block's copy-button row, in order, and derive its click target. */
function locateCopyHits(plainLines: readonly string[], sources: readonly string[]): CopyHit[] {
  const hits: CopyHit[] = [];
  const buttonWidth = visibleWidth(COPY_LABEL);
  let y = 0;

  for (const source of sources) {
    while (y < plainLines.length && !(plainLines[y] ?? "").includes(COPY_ANCHOR)) y++;
    if (y >= plainLines.length) break;

    const line = plainLines[y] ?? "";
    const startX = visibleWidth(line.slice(0, line.lastIndexOf(COPY_ANCHOR)));
    hits.push({ y, startX, endX: startX + buttonWidth, source });
    y++;
  }

  return hits;
}

function buildCard(
  highlighted: readonly string[],
  cardWidth: number,
  codeIndent: string,
  bg: (value: string) => string,
  accent: (value: string) => string,
): string[] {
  const innerWidth = Math.max(1, cardWidth - CARD_PAD.length * 2);
  const buttonWidth = visibleWidth(COPY_LABEL);
  const align = (line: string): string =>
    line.startsWith(codeIndent) ? line.slice(codeIndent.length) : line;
  const firstLine = highlighted[0] === undefined ? "" : align(highlighted[0]);
  const firstLineWidth = Math.max(1, innerWidth - buttonWidth - CARD_PAD.length);
  const wrappedFirstLine = wrapTextWithAnsi(firstLine, firstLineWidth);
  const firstLineContent = wrappedFirstLine[0] ?? "";
  const gapWidth = Math.max(1, innerWidth - visibleWidth(firstLineContent) - buttonWidth);
  const card = [
    fillRow("", cardWidth, bg),
    fillRow(
      `${CARD_PAD}${firstLineContent}${" ".repeat(gapWidth)}${accent(COPY_ANCHOR)}${CARD_PAD}`,
      cardWidth,
      bg,
    ),
  ];

  for (const line of wrappedFirstLine.slice(1)) {
    card.push(fillRow(`${CARD_PAD}${line}${CARD_PAD}`, cardWidth, bg));
  }

  for (const line of highlighted.slice(1)) {
    const wrapped = wrapTextWithAnsi(align(line), innerWidth);
    for (const wrappedLine of wrapped.length > 0 ? wrapped : [""]) {
      card.push(fillRow(`${CARD_PAD}${wrappedLine}${CARD_PAD}`, cardWidth, bg));
    }
  }

  card.push(fillRow("", cardWidth, bg));
  return card;
}

function installPatch(
  getTheme: () => ExtensionContext["ui"]["theme"],
  copyCode: (source: string) => void,
): () => void {
  const prototype = Markdown.prototype as unknown as MarkdownWithPrivateRenderer &
    Record<PropertyKey, PatchRecord | undefined>;
  prototype[PATCH]?.restore();

  const originalRenderToken = prototype.renderToken;
  const originalRender = prototype.render;
  const originalHandleMouse = prototype.handleMouse;

  const captureSources = new WeakMap<Markdown, string[]>();
  /** Survives cached renders, where renderToken only fires on cold renders. */
  const knownSources = new WeakMap<Markdown, string[]>();
  const pressedHits = new WeakMap<Markdown, CopyHit>();
  const layoutCache = new WeakMap<Markdown, LayoutCache>();

  const getText = (instance: Markdown): string =>
    (instance as unknown as { text?: string }).text ?? "";

  /**
   * User messages and thinking blocks pass a defaultTextStyle to Markdown;
   * assistant transcript text does not. Keep Pi's native rendering there.
   */
  const isPlainTextContext = (instance: Markdown): boolean =>
    !!(instance as unknown as { defaultTextStyle?: unknown }).defaultTextStyle;

  const cacheLayout = (
    instance: Markdown,
    key: string,
    lines: string[],
    hits: CopyHit[] = [],
  ): string[] => {
    layoutCache.set(instance, { key, hits, lines });
    return lines;
  };

  const patchedRenderToken = function (
    this: Markdown,
    token: CodeToken,
    width: number,
    nextTokenType?: string,
    styleContext?: unknown,
  ): string[] {
    if (token?.type !== "code") {
      return originalRenderToken.call(this, token, width, nextTokenType, styleContext);
    }

    const normalized = normalizeCodeToken(token, languageFromInfo(token.lang));
    const source = token.text ?? "";

    // Plain contexts (user messages, thinking) and empty tokens from stray or
    // unterminated fences keep Pi's native presentation.
    if (isPlainTextContext(this) || source.trim() === "") {
      return originalRenderToken.call(this, normalized, width, nextTokenType, styleContext);
    }

    captureSources.get(this)?.push(source);
    const rendered = originalRenderToken.call(this, normalized, width, nextTokenType, styleContext);

    // Scan backwards for the closing fence: code content may itself contain
    // bare fence rows, and only the last one is the one Pi appended.
    let closingFence = -1;
    for (let lineIndex = rendered.length - 1; lineIndex > 0; lineIndex--) {
      if (stripTerminalSequences(rendered[lineIndex] ?? "").trim() === "```") {
        closingFence = lineIndex;
        break;
      }
    }

    if (closingFence < 1) return rendered; // Pi's output shape changed; bail out.

    const theme = getTheme();
    const card = buildCard(
      rendered.slice(1, closingFence),
      Math.max(1, width),
      (this as unknown as { theme?: { codeBlockIndent?: string } }).theme?.codeBlockIndent ?? "  ",
      (value) => theme.bg(CARD_BG, value),
      (value) => theme.fg("accent", value),
    );
    if (nextTokenType && nextTokenType !== "space") card.push("");
    return card;
  };

  const patchedRender = function (this: Markdown, width: number): string[] {
    const key = `${width}\u0000${getText(this)}`;
    const cached = layoutCache.get(this);
    if (cached?.key === key) return cached.lines;

    if (isPlainTextContext(this)) {
      knownSources.delete(this);
      return cacheLayout(this, key, originalRender.call(this, width));
    }

    const currentSources: string[] = [];
    captureSources.set(this, currentSources);
    let lines: string[];
    try {
      lines = originalRender.call(this, width);
    } finally {
      captureSources.delete(this);
    }

    // Never key this on the source text: an indented code block has no ```
    // but is still rendered as a card.
    if (currentSources.length > 0) {
      knownSources.set(this, currentSources);
    } else if (!lines.some((line) => line.includes(COPY_ANCHOR))) {
      knownSources.delete(this);
    }

    const sources = knownSources.get(this) ?? [];
    if (sources.length === 0) return cacheLayout(this, key, lines);

    const plainLines = lines.map((line) => stripTerminalSequences(line));
    return cacheLayout(this, key, lines, locateCopyHits(plainLines, sources));
  };

  const patchedHandleMouse = function (
    this: Markdown,
    event: TuiMouseEvent,
  ): TuiMouseEventResult | undefined {
    if (event.button !== "left") return originalHandleMouse?.call(this, event);

    const hitAt = (y: number, x: number): CopyHit | undefined =>
      layoutCache.get(this)?.hits.find((item) => item.y === y && x >= item.startX && x < item.endX);

    if (event.type === "press") {
      const hit = hitAt(event.y, event.x);
      if (!hit) {
        pressedHits.delete(this);
        return originalHandleMouse?.call(this, event);
      }
      pressedHits.set(this, hit);
      return { handled: true, capture: true };
    }

    const pressed = pressedHits.get(this);
    if (!pressed) return originalHandleMouse?.call(this, event);

    // A held button reports motion at cell granularity, so a plain click
    // routinely arrives as press, drag, release; only the release decides.
    if (event.type === "release") {
      pressedHits.delete(this);
      const hit = hitAt(event.y, event.x);
      if (hit?.y === pressed.y && hit.source === pressed.source) copyCode(pressed.source);
      return { handled: true };
    }

    return { handled: true, render: false };
  };

  prototype.renderToken = patchedRenderToken;
  prototype.render = patchedRender;
  prototype.handleMouse = patchedHandleMouse;

  const record: PatchRecord = {
    restore() {
      if (prototype.renderToken === patchedRenderToken) prototype.renderToken = originalRenderToken;
      if (prototype.render === patchedRender) prototype.render = originalRender;
      if (prototype.handleMouse === patchedHandleMouse) {
        if (originalHandleMouse) prototype.handleMouse = originalHandleMouse;
        else delete prototype.handleMouse;
      }
      if (prototype[PATCH] === record) delete prototype[PATCH];
    },
  };
  prototype[PATCH] = record;
  return record.restore;
}

export default function (pi: ExtensionAPI) {
  let restore: (() => void) | undefined;
  let themeContext: ExtensionContext | undefined;
  let statusTimer: ReturnType<typeof setTimeout> | undefined;

  /** Transient footer feedback; ui.notify("info") would persist in the transcript. */
  const showCopiedStatus = (message: string) => {
    const ctx = themeContext;
    if (!ctx) return;
    try {
      if (statusTimer) clearTimeout(statusTimer);
      ctx.ui.setStatus(STATUS_KEY, message);
      statusTimer = setTimeout(() => {
        statusTimer = undefined;
        try {
          ctx.ui.setStatus(STATUS_KEY, undefined);
        } catch {
          // Stale ctx after reload or session replacement; nothing to clear.
        }
      }, STATUS_CLEAR_MS);
    } catch {
      // Stale ctx; fall back silently.
    }
  };

  const copyCode = async (source: string, ctx: ExtensionContext) => {
    try {
      await copyToClipboard(source);
      showCopiedStatus("Code copied");
    } catch (error) {
      ctx.ui.notify(error instanceof Error ? error.message : String(error), "warning");
    }
  };

  /** Reset session-scoped state; safe to run when no session is active. */
  const resetSessionState = () => {
    restore?.();
    restore = undefined;
    themeContext = undefined;
    if (statusTimer) {
      clearTimeout(statusTimer);
      statusTimer = undefined;
    }
  };

  pi.on("session_start", (_event, ctx) => {
    resetSessionState();
    if (ctx.mode !== "tui") return;

    themeContext = ctx;
    restore = installPatch(
      () => {
        if (!themeContext) throw new Error("pi-code-render has no active TUI theme");
        return themeContext.ui.theme;
      },
      (source) => {
        if (themeContext) void copyCode(source, themeContext);
      },
    );
  });

  pi.on("session_shutdown", () => {
    resetSessionState();
  });
}
