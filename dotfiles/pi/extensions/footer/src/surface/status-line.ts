import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { renderSegment, SEGMENTS } from "../segments.js";
import type { FooterStyles, TextStyler } from "../theme.js";
import type { FooterState, SegmentRenderContext, SegmentRenderResult, WidthMode } from "../types.js";

const RESET = "\x1b[0m";

function applySegmentStyle(segment: SegmentRenderResult, styles: FooterStyles): string {
  return styles.segments[segment.id](segment.text);
}

function widthModeFor(width: number): WidthMode {
  if (width < 64) return "minimal";
  if (width < 96) return "compact";
  return "full";
}

type Join = { styles: FooterStyles; separator: string };

function joinSegments({ styles, separator }: Join, segments: SegmentRenderResult[]): { text: string; width: number } {
  if (segments.length === 0) return { text: "", width: 0 };
  const text = `${segments.map((segment) => applySegmentStyle(segment, styles)).join(separator)}${RESET}`;
  return { text, width: visibleWidth(text) };
}

function fitSegments(join: Join, segments: SegmentRenderResult[], width: number): SegmentRenderResult[] {
  const fitted = [...segments];
  let joined = joinSegments(join, fitted);
  while (fitted.length > 0 && joined.width > width) {
    // Display order ranks ordinary facts, but Model always survives last.
    // Try the trailing fact's shorter labels before removing any fact.
    const last = fitted.at(-1)!;
    const remaining = width - (joined.width - visibleWidth(last.text));
    const shorter = last.fit?.(remaining);
    if (shorter !== undefined) {
      fitted[fitted.length - 1] = { ...last, text: shorter };
      return fitted;
    }
    if (fitted.length === 1) break;
    const removable = last.id === "model" ? fitted.length - 2 : fitted.length - 1;
    fitted.splice(removable, 1);
    joined = joinSegments(join, fitted);
  }
  return fitted;
}

function renderLine(state: FooterState, width: number, styles: FooterStyles, border: TextStyler): string {
  const safeWidth = Number.isFinite(width) ? Math.max(0, Math.floor(width)) : 0;
  const widthMode = widthModeFor(safeWidth);
  const ctx: SegmentRenderContext = {
    state,
    widthMode,
    styles,
  };
  const segments = SEGMENTS.map((segment) => renderSegment(ctx, segment)).filter((segment) => segment !== undefined);
  const join = { styles, separator: border(" ── ") };
  const line = joinSegments(join, fitSegments(join, segments, safeWidth));
  return line.width > safeWidth ? truncateToWidth(line.text, safeWidth, styles.dim("…")) : line.text;
}

export class StatusLineRenderer {
  private cached?: {
    state: FooterState;
    version: number;
    width: number;
    styles: FooterStyles;
    border: TextStyler;
    text: string;
  };

  /** `border` is the frame's current border color, which pi changes with the thinking level. */
  render(state: FooterState, width: number, styles: FooterStyles, border: TextStyler): string {
    const previous = this.cached;
    if (
      previous?.state === state &&
      previous.version === state.version &&
      previous.width === width &&
      previous.styles === styles &&
      previous.border === border
    ) {
      return previous.text;
    }
    const text = renderLine(state, width, styles, border);
    this.cached = { state, version: state.version, width, styles, border, text };
    return text;
  }
}
