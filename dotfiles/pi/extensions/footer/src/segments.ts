import { visibleWidth } from "@earendil-works/pi-tui";
import type {
  SegmentData,
  SegmentDefinition,
  SegmentRenderContext,
  SegmentRenderResult,
  UsageTotals,
} from "./types.js";

const graphemes = new Intl.Segmenter(undefined, { granularity: "grapheme" });

export function formatTokens(count: number | null | undefined): string {
  if (count === null || count === undefined || !Number.isFinite(count)) return "?";
  const abs = Math.abs(count);
  if (abs < 1000) return `${Math.round(count)}`;
  if (abs < 10_000) return `${(count / 1000).toFixed(1)}k`;
  if (abs < 1_000_000) return `${Math.round(count / 1000)}k`;
  if (abs < 10_000_000) return `${(count / 1_000_000).toFixed(1)}M`;
  return `${Math.round(count / 1_000_000)}M`;
}

function formatPercent(percent: number | null | undefined): string {
  if (percent === null || percent === undefined || !Number.isFinite(percent)) return "?";
  return percent >= 10 ? `${percent.toFixed(0)}%` : `${percent.toFixed(1)}%`;
}

function collectGit(ctx: SegmentRenderContext): SegmentData | undefined {
  return ctx.state.branch ? { primary: ctx.state.branch } : undefined;
}

function collectContext(ctx: SegmentRenderContext): SegmentData {
  const { tokens, window, percent } = ctx.state.context;
  const { bright } = ctx.styles;
  const fill = Math.min(100, Math.max(0, percent ?? 0));
  const tone = fill >= 85 ? bright.red : fill >= 70 ? bright.orange : fill >= 50 ? bright.yellow : bright.green;
  const pct = tone(formatPercent(percent));
  const bar = (size: number) => {
    const filled = Math.round((fill / 100) * size);
    return `${bright.gray("[")}${tone("█".repeat(filled))}${bright.gray(`${"░".repeat(size - filled)}]`)}`;
  };
  return {
    primary: pct,
    display: {
      full: `${bar(20)} ${bright.white(`${formatTokens(tokens)}/${formatTokens(window)}`)} ${pct}`,
      compact: `${bar(5)} ${pct}`,
      minimal: pct,
    },
  };
}

function sessionCacheHitPercent(usage: UsageTotals): number | undefined {
  const promptTokens = usage.input + usage.cacheRead + usage.cacheWrite;
  return promptTokens > 0 ? Math.round((usage.cacheRead / promptTokens) * 100) : undefined;
}

function collectTokens(ctx: SegmentRenderContext): SegmentData | undefined {
  const hitRate = sessionCacheHitPercent(ctx.state.usage);
  if (hitRate === undefined) return undefined;
  const { bright } = ctx.styles;
  const tone = hitRate >= 90 ? bright.green : hitRate >= 71 ? bright.yellow : bright.white;
  return {
    primary: `${tone(`${hitRate}%`)} ${bright.white("cached")}`,
    display: { minimal: tone(`${hitRate}%`) },
  };
}

function withoutProviderPrefix(name: string, provider: string | undefined): string {
  if (!provider) return name;
  const prefix = `${provider}-`;
  return name.length > prefix.length && name.toLowerCase().startsWith(prefix.toLowerCase())
    ? name.slice(prefix.length)
    : name;
}

function collectModel(ctx: SegmentRenderContext): SegmentData {
  const { id, displayName, provider } = ctx.state.model;
  const originalName = (displayName || id || "").replace(/^.*\//, "") || "no-model";
  const shortName = withoutProviderPrefix(originalName, provider);
  const name = ctx.widthMode === "minimal" ? shortName : originalName;
  const thinking = ctx.state.model.thinking || "off";
  const suffix =
    thinking !== "off" && ctx.widthMode === "full" ? `: ${thinking.charAt(0).toUpperCase()}${thinking.slice(1)}` : "";
  const alternatives = suffix ? [name] : [];
  if (shortName !== name) alternatives.push(shortName);
  return {
    primary: `${name}${suffix}`,
    fit: { alternatives, name: { prefix: "", value: shortName, suffix: "" } },
  };
}

export const SEGMENTS: readonly SegmentDefinition[] = [
  { id: "git", icon: "\ue725", collect: collectGit },
  { id: "context", icon: "󰔟", collect: collectContext },
  { id: "tokens", icon: "󰄨", collect: collectTokens },
  { id: "model", icon: "", collect: collectModel },
];

function middleEllipsis(text: string, width: number): string | undefined {
  if (visibleWidth(text) <= width) return text;
  // Less than three columns at each end rarely identifies a model usefully.
  if (width < 7) return undefined;
  const parts = Array.from(graphemes.segment(text), ({ segment }) => ({ text: segment, width: visibleWidth(segment) }));
  const headBudget = Math.ceil((width - 1) / 2);
  let head = "",
    tail = "",
    headWidth = 0,
    tailWidth = 0,
    first = 0;
  while (first < parts.length && headWidth + parts[first]!.width <= headBudget) {
    head += parts[first]!.text;
    headWidth += parts[first++]!.width;
  }
  for (let last = parts.length - 1; last >= first && tailWidth + parts[last]!.width <= width - 1 - headWidth; last--) {
    tail = parts[last]!.text + tail;
    tailWidth += parts[last]!.width;
  }
  return head && tail ? `${head}…${tail}` : undefined;
}

function fitCollectedSegment(
  fit: NonNullable<SegmentData["fit"]>,
  iconPrefix: string,
  width: number,
): string | undefined {
  for (const alternative of fit.alternatives) {
    const text = `${iconPrefix}${alternative}`.trim();
    if (visibleWidth(text) <= width) return text;
  }
  const prefix = `${iconPrefix}${fit.name.prefix}`;
  const name = middleEllipsis(fit.name.value, width - visibleWidth(prefix) - visibleWidth(fit.name.suffix));
  return name === undefined ? undefined : `${prefix}${name}${fit.name.suffix}`.trim();
}

function displayForMode(data: SegmentData, widthMode: SegmentRenderContext["widthMode"]): string {
  const display = data.display?.[widthMode];
  if (display !== undefined) return display;
  return data.primary;
}

export function renderSegment(ctx: SegmentRenderContext, segment: SegmentDefinition): SegmentRenderResult | undefined {
  const data = segment.collect(ctx);
  if (!data) return undefined;
  const prefix = `${ctx.styles.icons[segment.id]?.(segment.icon) ?? segment.icon} `;
  const fit = data.fit;
  return {
    id: segment.id,
    text: `${prefix}${displayForMode(data, ctx.widthMode)}`.trim(),
    ...(fit ? { fit: (width: number) => fitCollectedSegment(fit, prefix, width) } : {}),
  };
}
