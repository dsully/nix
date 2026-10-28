import type { Theme } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { ansiGreen, ansiYellow } from "./constants.js";
import { frameGlyphs, glyphs } from "./glyphs.js";
import type { SkillEntry } from "./types.js";

export function inlineLine(text: string): string {
  return text.replace(/[\r\n]+/g, " ").replace(/\t/g, " ");
}

export function padAnsi(text: string, width: number): string {
  const safeWidth = Math.max(0, width);
  const truncated = truncateToWidth(inlineLine(text), safeWidth, "");
  return `${truncated}${" ".repeat(Math.max(0, safeWidth - visibleWidth(truncated)))}`;
}

export function skillEntityTitle(theme: Theme, label: string): string {
  return theme.fg("text", theme.bold(label));
}

export function skillSelectedLine(theme: Theme, line: string, width: number): string {
  return theme.bg("selectedBg", padAnsi(line, width));
}

export function skillKeyHints(theme: Theme, hints: Array<[key: string, description: string]>): string {
  return hints
    .map(([key, description]) => `${ansiYellow(key)} ${theme.fg("dim", description)}`)
    .join(theme.fg("dim", ` ${glyphs().bullet.trim()} `));
}

function frameLine(theme: Theme, line: string, innerWidth: number): string {
  const clipped = truncateToWidth(inlineLine(line), innerWidth, theme.fg("dim", "..."));
  const frame = frameGlyphs();
  return `${theme.fg("borderAccent", `${frame.v} `)}${padAnsi(clipped, innerWidth)}${theme.fg("borderAccent", ` ${frame.v}`)}`;
}

function fitFrameBody(theme: Theme, lines: string[], fixedInnerRows?: number): string[] {
  if (fixedInnerRows === undefined) return lines;
  const rowCount = Math.max(1, Math.floor(fixedInnerRows));
  if (lines.length > rowCount) {
    const hidden = lines.length - rowCount + 1;
    return [...lines.slice(0, Math.max(0, rowCount - 1)), theme.fg("dim", `↓ ${hidden} more line(s)`)].slice(
      0,
      rowCount,
    );
  }
  if (lines.length < rowCount) return [...lines, ...Array.from({ length: rowCount - lines.length }, () => "")];
  return lines;
}

export function renderFrame(
  theme: Theme,
  width: number,
  lines: string[],
  fixedInnerRows?: number,
  title = "",
  right = "",
): string[] {
  const body = fitFrameBody(theme, lines, fixedInnerRows);
  if (width < 6) return body.map((line) => truncateToWidth(inlineLine(line), width, ""));
  const innerWidth = Math.max(1, width - 4);
  const frame = frameGlyphs();
  const top = () => {
    const contentWidth = innerWidth + 2;
    if (!title && !right) return theme.fg("borderAccent", `${frame.tl}${frame.h.repeat(contentWidth)}${frame.tr}`);
    const rightPlain = right ? ` ${right} ` : "";
    const titleBudget = Math.max(1, contentWidth - visibleWidth(rightPlain) - 1);
    const titlePlain = title ? ` ${truncateToWidth(title, Math.max(1, titleBudget - 2), glyphs().ellipsis)} ` : "";
    const fill = Math.max(1, contentWidth - visibleWidth(titlePlain) - visibleWidth(rightPlain));
    return `${theme.fg("borderAccent", frame.tl)}${titlePlain ? ansiGreen(titlePlain) : ""}${theme.fg("borderAccent", frame.h.repeat(fill))}${rightPlain ? theme.fg("dim", rightPlain) : ""}${theme.fg("borderAccent", frame.tr)}`;
  };
  return [
    top(),
    ...body.map((line) => frameLine(theme, line, innerWidth)),
    theme.fg("borderAccent", `${frame.bl}${frame.h.repeat(innerWidth + 2)}${frame.br}`),
  ].map((line) => truncateToWidth(inlineLine(line), width, ""));
}

function centerLines(lines: string[], width: number): string[] {
  const renderedWidth = lines.reduce((max, line) => Math.max(max, visibleWidth(line)), 0);
  const leftPad = Math.max(0, Math.floor((width - renderedWidth) / 2));
  return leftPad === 0 ? lines : lines.map((line) => `${" ".repeat(leftPad)}${line}`);
}

export function renderCenteredDialog(theme: Theme, width: number, lines: string[], maxInnerWidth = 68): string[] {
  if (width < 8) return lines.map((line) => truncateToWidth(line, width, ""));
  const innerWidth = Math.max(1, Math.min(width - 4, maxInnerWidth));
  const frame = frameGlyphs();
  const framed = [
    theme.fg("borderAccent", `${frame.tl}${frame.h.repeat(innerWidth + 2)}${frame.tr}`),
    ...lines.map((line) => frameLine(theme, line, innerWidth)),
    theme.fg("borderAccent", `${frame.bl}${frame.h.repeat(innerWidth + 2)}${frame.br}`),
  ];
  return centerLines(framed, width);
}

export function packageLabel(skill: SkillEntry): string | undefined {
  return skill.origin === "package" && skill.source ? skill.source : undefined;
}
