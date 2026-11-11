import { getLanguageFromPath, highlightCode } from "@earendil-works/pi-coding-agent";
import { type Component, truncateToWidth, visibleWidth, wrapTextWithAnsi } from "@earendil-works/pi-tui";
import { lstatSync, statSync } from "node:fs";
import { join } from "node:path";
import type { GrepRow, ListRow, ReadRow } from "./code.js";
import { type DiffLine, keepBackground, markRanges, type Range } from "./diff.js";
import { type EntryKind, type EntryStyle, entryStyle, type LlaTheme } from "./lla.js";
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

function highlighted(code: readonly string[], lang: string | undefined): string[] {
  if (!lang) return [...code];
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
  const code = highlighted(
    diff.map((line) => line.text),
    lang,
  );
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

export type View = (width: number) => string[];
type Pair = readonly [head: string, text: string];

/** Rows colored once and wrapped at each render. */
const hangingView =
  (pairs: readonly Pair[]): View =>
  (width) =>
    pairs.flatMap(([head, text]) => hanging(head, text, width));

const untabbed = (text: string) => text.replace(/\t/g, "   ");

/** A read's rows with dim line numbers and anchors, the code colored for the file's language. */
export function readView(theme: Theme, rows: readonly ReadRow[], path: string | undefined): View {
  const lang = path ? getLanguageFromPath(path) : undefined;
  const source = rows.flatMap((row) => (row.kind === "code" ? [untabbed(row.text)] : []));
  const code = lang ? highlighted(source, lang) : source.map((text) => theme.fg("toolOutput", text));
  const digits = String(rows.findLast((row) => row.kind === "code")?.line ?? 1).length;
  let next = 0;
  return hangingView(
    rows.map((row): Pair =>
      row.kind === "note"
        ? ["  ", theme.fg("dim", row.text)]
        : [`  ${theme.fg("dim", `${String(row.line).padStart(digits)} ${row.anchor}│`)}`, code[next++] ?? ""],
    ),
  );
}

const MATCH_BAND = { dark: "\x1b[48;2;76;86;106m", light: "\x1b[48;2;216;222;233m" };

/** Grep hits colored for their file's language, matches under a band; context lines stay dim. */
export function grepView(theme: Theme, rows: readonly GrepRow[], ranges: (text: string) => Range[]): View {
  const band = `${theme.appearance === "light" ? MATCH_BAND.light : MATCH_BAND.dark}\x1b[1m`;
  const digits = Math.max(...rows.map((row) => (row.kind === "hit" ? String(row.line).length : 1)));
  let lang: string | undefined;
  return hangingView(
    rows.map((row): Pair => {
      if (row.kind === "file") {
        lang = getLanguageFromPath(row.path);
        return ["  ", theme.bold(theme.fg("accent", row.path))];
      }
      if (row.kind === "note") return ["  ", theme.fg("dim", row.text)];
      const text = untabbed(row.text);
      const gutter = `  ${theme.fg("dim", `${String(row.line).padStart(digits)} ${row.anchor ?? ""}│`)}`;
      if (!row.match) return [gutter, theme.fg("dim", text)];
      const code = lang ? (highlighted([text], lang)[0] ?? text) : theme.fg("toolOutput", text);
      return [gutter, markRanges(code, ranges(text), band, `${BG_RESET}\x1b[22m`)];
    }),
  );
}

/** Pi's ls rows painted the way `lla` paints names, from its theme; plain without one. */
export function listView(theme: Theme, rows: readonly ListRow[], dir: string, lla: LlaTheme | null): View {
  return hangingView(
    rows.map((row): Pair => {
      if (row.kind === "note") return ["  ", theme.fg("dim", row.text)];
      const name = row.dir ? `${row.name}/` : row.name;
      if (!lla) return ["  ", theme.fg("toolOutput", name)];
      return ["  ", paint(entryStyle(lla, row.name, row.dir ? "dir" : fileKind(join(dir, row.name))), name)];
    }),
  );
}

function fileKind(path: string): EntryKind {
  try {
    if (lstatSync(path).isSymbolicLink()) return "symlink";
    return statSync(path).mode & 0o111 ? "exec" : "file";
  } catch {
    return "file";
  }
}

function paint(style: EntryStyle, text: string): string {
  const rgb = /^#([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/i.exec(style.color ?? "");
  const open = [
    rgb
      ? `\x1b[38;2;${rgb
          .slice(1)
          .map((hex) => parseInt(hex, 16))
          .join(";")}m`
      : "",
    style.bold ? "\x1b[1m" : "",
    style.italic ? "\x1b[3m" : "",
    style.underline ? "\x1b[4m" : "",
  ].join("");
  return open ? `${open}${text}\x1b[0m` : text;
}

/** A shell command colored as bash, its first line after the status mark. */
export function shellView(mark: string, command: string): View {
  const code = highlighted(untabbed(command).split("\n"), "bash");
  return hangingView(code.map((line, i): Pair => [i === 0 ? mark : "  ", line]));
}

/** `text` wrapped to the width left after `head`, later lines indented to line up under its first. */
function hanging(head: string, text: string, width: number): string[] {
  const indent = " ".repeat(visibleWidth(head));
  const wrapped = wrapTextWithAnsi(text, Math.max(1, width - indent.length));
  return (wrapped.length ? wrapped : [""]).map((line, i) => (i === 0 ? head : indent) + line);
}
