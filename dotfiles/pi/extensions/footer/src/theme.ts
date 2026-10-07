import type { Theme, ThemeColor } from "@earendil-works/pi-coding-agent";
import type { SegmentId } from "./types.js";

export type TextStyler = (text: string) => string;

const SEGMENT_COLORS: Record<SegmentId, ThemeColor> = {
	git: "success",
	throughput: "muted",
	context: "text",
	tokens: "muted",
	model: "accent",
};

export interface FooterStyles {
	text: TextStyler;
	dim: TextStyler;
	warn: TextStyler;
	error: TextStyler;
	separator: TextStyler;
	border: TextStyler;
	title: TextStyler;
	path: TextStyler;
	segments: Record<SegmentId, TextStyler>;
}

const cache = new WeakMap<Theme, FooterStyles>();

/** Pi replaces the Theme instance on switch, so identity is a valid cache key. */
export function stylesFor(theme: Theme): FooterStyles {
	let styles = cache.get(theme);
	if (styles) return styles;
	const fg = (color: ThemeColor): TextStyler => text => theme.fg(color, text);
	styles = {
		text: fg("text"),
		dim: fg("dim"),
		warn: fg("warning"),
		error: fg("error"),
		separator: fg("dim"),
		border: fg("border"),
		title: fg("accent"),
		path: fg("mdLink"),
		segments: Object.fromEntries(Object.entries(SEGMENT_COLORS).map(([id, color]) => [id, fg(color)])) as Record<SegmentId, TextStyler>,
	};
	cache.set(theme, styles);
	return styles;
}
