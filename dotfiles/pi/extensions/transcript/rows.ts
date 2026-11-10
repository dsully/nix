import { getLanguageFromPath, highlightCode } from "@earendil-works/pi-coding-agent";
import { type Component, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { type DiffLine, keepBackground, markRanges } from "./diff.js";
import type { Tail } from "./tail.js";

export type Theme = {
  fg: (color: string, text: string) => string;
  bold: (text: string) => string;
  italic: (text: string) => string;
  appearance?: string;
};

export type Status = "streaming" | "running" | "done" | "failed";

const GLYPH_COLOR: Record<Status, string> = { streaming: "dim", running: "accent", done: "muted", failed: "error" };
const TEXT_COLOR: Record<Status, string> = {
  streaming: "toolTitle",
  running: "toolTitle",
  done: "muted",
  failed: "toolTitle",
};

/** Components this extension returns; a wrapped renderer never gets one back as its lastComponent. */
const OURS = new WeakSet<object>();

export function lines(render: (width: number) => string[]): Component {
  const component = { invalidate() {}, render };
  OURS.add(component);
  return component;
}

export const empty = (): Component => lines(() => []);

export function theirs(component: unknown): Component | undefined {
  return component && !OURS.has(component as object) ? (component as Component) : undefined;
}

export function glyphMark(theme: Theme, glyph: string, status: Status): string {
  return `${theme.fg(GLYPH_COLOR[status], theme.bold(glyph))} `;
}

export function glyphLine(
  theme: Theme,
  glyph: string,
  status: Status,
  text: string,
  width: number,
  suffix = "",
): string {
  const head = glyphMark(theme, glyph, status);
  const room = Math.max(1, width - visibleWidth(head) - visibleWidth(suffix));
  return head + truncateToWidth(theme.fg(TEXT_COLOR[status], text.replace(/\s*\n\s*/g, " ")), room) + suffix;
}

const TONE: Record<Tail["tone"], string> = {
  muted: "muted",
  dim: "dim",
  error: "error",
  warning: "warning",
  text: "text",
};

export function tailLine(theme: Theme, tail: Tail, width: number): string {
  const head = `  ${theme.fg("dim", "⎿")} `;
  const suffix = tail.suffix ? theme.fg("dim", ` · ${tail.suffix}`) : "";
  const room = Math.max(1, width - visibleWidth(head) - visibleWidth(suffix));
  return head + truncateToWidth(theme.fg(TONE[tail.tone], tail.text.replace(/\s*\n\s*/g, " ")), room) + suffix;
}

/** Another renderer's component, inset by two columns, with a status glyph on its first line. */
export function framed(inner: Component, mark: string): Component {
  return lines((width) => inner.render(Math.max(10, width - 2)).map((line, i) => (i === 0 ? mark : "  ") + line));
}

// Diff bands from pi-polish (MIT, Copyright (c) 2026 Thomas van Dongen), extensions/tools.ts.
const PALETTES = {
  dark: {
    added: "\x1b[48;2;13;46;16m",
    removed: "\x1b[48;2;63;12;16m",
    addedWord: "\x1b[48;2;31;95;38m",
    removedWord: "\x1b[48;2;122;30;36m",
    addedGutter: "\x1b[38;2;120;200;120m",
    removedGutter: "\x1b[38;2;230;120;120m",
  },
  light: {
    added: "\x1b[48;2;230;255;236m",
    removed: "\x1b[48;2;255;235;233m",
    addedWord: "\x1b[48;2;171;242;188m",
    removedWord: "\x1b[48;2;255;206;203m",
    addedGutter: "\x1b[38;2;26;127;55m",
    removedGutter: "\x1b[38;2;207;34;46m",
  },
};
const BG_RESET = "\x1b[49m";
const FG_RESET = "\x1b[39m";
const DIFF_INDENT = "    ";

function highlighted(lines: readonly DiffLine[], lang: string | undefined): string[] {
  const code = lines.map((line) => line.text);
  if (!lang) return code;
  try {
    const out = highlightCode(code.join("\n"), lang);
    if (out.length === code.length) return out;
  } catch {}
  return code.map((text) => highlightCode(text, lang)[0] ?? text);
}

/** Diff rows with syntax colors, a tinted band per added or removed line, and changed words marked brighter. */
export function diffLines(theme: Theme, diff: readonly DiffLine[], path: string | undefined, width: number): string[] {
  const palette = theme.appearance === "light" ? PALETTES.light : PALETTES.dark;
  const lang = path ? getLanguageFromPath(path) : undefined;
  const code = highlighted(diff, lang);
  const digits = Math.max(...diff.map((line) => String(line.line ?? "").length), 1);
  return diff.map((line, i) => {
    if (line.kind === "gap") return theme.fg("dim", `${DIFF_INDENT}${" ".repeat(digits)} ⋮`);
    const number = String(line.line ?? "").padStart(digits);
    if (line.kind === "ctx") {
      return truncateToWidth(`${DIFF_INDENT}${theme.fg("dim", `${number}  `)} ${code[i]}`, width);
    }
    const added = line.kind === "add";
    const band = added ? palette.added : palette.removed;
    const gutter = `${added ? palette.addedGutter : palette.removedGutter}${number} ${added ? "+" : "-"}${FG_RESET}`;
    const body = markRanges(
      code[i] ?? line.text,
      line.marks ?? [],
      added ? palette.addedWord : palette.removedWord,
      band,
    );
    const row = truncateToWidth(`${DIFF_INDENT}${gutter} ${body}`, width);
    const pad = " ".repeat(Math.max(0, width - visibleWidth(row)));
    return `${band}${keepBackground(row, band)}${pad}${BG_RESET}`;
  });
}
