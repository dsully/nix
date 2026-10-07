import { visibleWidth } from "@earendil-works/pi-tui";
import type { ModelSpeedMeasurement, SegmentData, SegmentDefinition, SegmentRenderContext, SegmentRenderResult, UsageTotals } from "./types.js";

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

function formatThroughputRate(rate: number): string {
	const scale = rate < 1_000 ? 1 : rate < 1_000_000 ? 1_000 : 1_000_000;
	const scaled = rate / scale;
	const value = scaled < 10 ? scaled.toFixed(1) : `${Math.round(scaled)}`;
	return `${value}${scale === 1 ? "" : scale === 1_000 ? "k" : "M"}`;
}

function validThroughput(turn: ModelSpeedMeasurement | null | undefined): turn is ModelSpeedMeasurement {
	const rate = turn?.tokensPerSecond;
	return typeof rate === "number" && Number.isFinite(rate) && rate > 0;
}

function collectThroughput(ctx: SegmentRenderContext): SegmentData {
	const { currentRun, lastRun } = ctx.state.throughput;
	const turn = validThroughput(currentRun) ? currentRun : validThroughput(lastRun) ? lastRun : undefined;
	const formatted = turn ? `${turn === currentRun ? "~" : ""}${formatThroughputRate(turn.tokensPerSecond)}` : "?";
	return {
		primary: `${formatted} tok/s`,
		display: { full: `${formatted} tok/s`, compact: `${formatted}/s`, minimal: `${formatted}/s` },
	};
}

function collectContext(ctx: SegmentRenderContext): SegmentData {
	const { tokens, window, percent } = ctx.state.context;
	const pct = formatPercent(percent);
	const ratio = `${formatTokens(tokens)}/${formatTokens(window)}`;
	return {
		tone: percent !== null && percent >= 90 ? "error" : percent !== null && percent >= 75 ? "warning" : "normal",
		primary: pct,
		display: {
			full: percent === null && tokens === null ? ratio : `${pct} ${ratio}`,
			compact: pct,
			minimal: pct,
		},
	};
}

function sessionCacheHitPercent(usage: UsageTotals): number | undefined {
	const promptTokens = usage.input + usage.cacheRead + usage.cacheWrite;
	return promptTokens > 0 ? Math.round((usage.cacheRead / promptTokens) * 100) : undefined;
}

function collectTokens(ctx: SegmentRenderContext): SegmentData {
	const usage = ctx.state.usage;
	const primary = `↑${formatTokens(usage.input)} ↓${formatTokens(usage.output)}`;
	const hitRate = sessionCacheHitPercent(usage);
	const rate = hitRate !== undefined ? `${hitRate}%` : undefined;
	return {
		primary,
		display: {
			// nf-md-refresh (U+F0450)
			full: rate ? `${primary} 󰑐${rate}` : primary,
			compact: rate ?? primary,
			minimal: rate ?? formatTokens(usage.input + usage.output),
		},
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
	const { id, displayName, provider: providerName } = ctx.state.model;
	const originalName = displayName || id || "no-model";
	const shortName = withoutProviderPrefix(originalName, providerName);
	const name = ctx.widthMode === "minimal" ? shortName : originalName;
	let provider = ctx.showProvider && providerName ? `${providerName}/` : "";
	const thinking = ctx.state.model.thinking || "off";
	const visibleThinking = thinking !== "off" && ctx.widthMode === "full" ? thinking : undefined;
	let suffix = visibleThinking ? ` ${visibleThinking}` : "";
	const model = `${provider}${name}`;
	const alternatives: string[] = [];
	if (provider) {
		provider = "";
		alternatives.push(`${name}${suffix}`);
	}
	if (suffix) {
		suffix = "";
		alternatives.push(`${provider}${name}`);
	}
	if (shortName !== name) alternatives.push(`${provider}${shortName}${suffix}`);
	return {
		primary: model,
		secondary: visibleThinking,
		fit: { alternatives, name: { prefix: provider, value: shortName, suffix } },
	};
}

export const SEGMENTS: readonly SegmentDefinition[] = [
	{ id: "git", icon: "\ue725", collect: collectGit },
	{ id: "throughput", icon: "\uf427", iconSpacing: 2, collect: collectThroughput },
	{ id: "context", icon: "󰔟", collect: collectContext },
	{ id: "tokens", icon: "󰄨", collect: collectTokens },
	{ id: "model", icon: "󰚩", collect: collectModel },
];

function middleEllipsis(text: string, width: number): string | undefined {
	if (visibleWidth(text) <= width) return text;
	// Less than three columns at each end rarely identifies a model usefully.
	if (width < 7) return undefined;
	const parts = Array.from(graphemes.segment(text), ({ segment }) => ({ text: segment, width: visibleWidth(segment) }));
	const headBudget = Math.ceil((width - 1) / 2);
	let head = "", tail = "", headWidth = 0, tailWidth = 0, first = 0;
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

function fitCollectedSegment(fit: NonNullable<SegmentData["fit"]>, iconPrefix: string, width: number): string | undefined {
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
	const secondary = data.secondary ? ` ${data.secondary}` : "";
	return `${data.primary}${secondary}`.trim();
}

export function renderSegment(ctx: SegmentRenderContext, segment: SegmentDefinition): SegmentRenderResult | undefined {
	const data = segment.collect(ctx);
	if (!data) return undefined;
	const prefix = `${segment.icon}${" ".repeat(segment.iconSpacing ?? 1)}`;
	const fit = data.fit;
	return {
		id: segment.id,
		tone: data.tone ?? "normal",
		text: `${prefix}${displayForMode(data, ctx.widthMode)}`.trim(),
		...(fit ? { fit: (width: number) => fitCollectedSegment(fit, prefix, width) } : {}),
	};
}
