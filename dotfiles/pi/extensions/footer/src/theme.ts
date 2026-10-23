import type { Theme, ThemeColor } from "@earendil-works/pi-coding-agent";
import type { SegmentId } from "./types.js";

export type TextStyler = (text: string) => string;

// Nord `*.bright` from modules/system/colors.nix; pi themes expose only fixed tokens, none of them bright.
// shortcut: duplicated hex, generate from colors.nix if the palette starts changing.
const BRIGHT = {
  white: ["#eceff4", "text"],
  gray: ["#667084", "dim"],
  green: ["#b1d196", "success"],
  yellow: ["#f0d399", "warning"],
  orange: ["#d89079", "warning"],
  orangeBase: ["#d08770", "warning"],
  red: ["#d06f79", "error"],
  blue: ["#5e81ac", "mdLink"],
} as const satisfies Record<string, readonly [string, ThemeColor]>;

export type BrightColor = keyof typeof BRIGHT;

const SEGMENT_COLORS: Record<SegmentId, BrightColor> = {
  git: "white",
  context: "white",
  tokens: "white",
  model: "white",
};

export interface FooterStyles {
  text: TextStyler;
  dim: TextStyler;
  warn: TextStyler;
  icons: Partial<Record<SegmentId, TextStyler>>;
  border: TextStyler;
  title: TextStyler;
  path: TextStyler;
  bright: Record<BrightColor, TextStyler>;
  segments: Record<SegmentId, TextStyler>;
}

const cache = new WeakMap<Theme, FooterStyles>();

/** Pi replaces the Theme instance on switch, so identity is a valid cache key. */
export function stylesFor(theme: Theme): FooterStyles {
  let styles = cache.get(theme);
  if (styles) return styles;
  const fg =
    (color: ThemeColor): TextStyler =>
    (text) =>
      theme.fg(color, text);
  const truecolor = theme.getColorMode() === "truecolor";
  const hex = ([color, fallback]: readonly [string, ThemeColor]): TextStyler => {
    if (!truecolor) return fg(fallback);
    const n = Number.parseInt(color.slice(1), 16);
    const open = `\x1b[38;2;${n >> 16};${(n >> 8) & 255};${n & 255}m`;
    return (text) => `${open}${text}\x1b[39m`;
  };
  const bright = Object.fromEntries(Object.entries(BRIGHT).map(([name, spec]) => [name, hex(spec)])) as Record<
    BrightColor,
    TextStyler
  >;
  styles = {
    text: fg("text"),
    dim: fg("dim"),
    warn: fg("warning"),
    icons: { tokens: bright.orangeBase },
    border: fg("border"),
    title: fg("accent"),
    path: fg("text"),
    bright,
    segments: Object.fromEntries(Object.entries(SEGMENT_COLORS).map(([id, color]) => [id, bright[color]])) as Record<
      SegmentId,
      TextStyler
    >,
  };
  cache.set(theme, styles);
  return styles;
}
