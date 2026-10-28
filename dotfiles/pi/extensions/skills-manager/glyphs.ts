const GLYPHS = {
  frame: { tl: "┏", tr: "┓", bl: "┗", br: "┛", h: "━", v: "┃" },
  bullet: "● ",
  ok: "✓",
  fail: "✗",
  ellipsis: "…",
} as const;

export function glyphs(): typeof GLYPHS {
  return GLYPHS;
}

export function frameGlyphs(): (typeof GLYPHS)["frame"] {
  return GLYPHS.frame;
}
