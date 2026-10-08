import { visibleWidth } from "@earendil-works/pi-tui";
import { formatWorkspaceLabel } from "./format.js";
import { truncatePlainText, truncateStyledText } from "./text.js";

const SURFACE_TITLE_MAX_WIDTH = 48;
const SURFACE_TITLE_RATIO = 0.42;
const SURFACE_TITLE_MIN_INNER_WIDTH = 16;
const SURFACE_TITLE_PADDING_X = 1;
export const SURFACE_CONTENT_PADDING_X = 1;
export const SURFACE_AUTOCOMPLETE_INDENT = 1 + SURFACE_CONTENT_PADDING_X;
const SURFACE_STATUS_CHROME_WIDTH = 3;

const SURFACE_BORDER = {
  topLeft: "╭",
  topRight: "╮",
  bottomLeft: "╰",
  bottomRight: "╯",
  vertical: "│",
  horizontal: "─",
} as const;

type SurfaceChunkRole = "border" | "title" | "status" | "content" | "text" | "dim";

interface SurfaceChunk {
  role: SurfaceChunkRole;
  text: string;
}

type SurfaceChunkRenderer = (text: string, chunk: SurfaceChunk) => string;
type SurfaceChunkRenderers = Partial<Record<SurfaceChunkRole, SurfaceChunkRenderer>>;

interface SurfaceMetrics {
  safeWidth: number;
  innerWidth: number;
}

interface SurfaceInlinePlan {
  chunks: SurfaceChunk[];
  width: number;
}

interface SurfaceStatusPlan {
  text: string;
  width: number;
}

interface SurfaceFramePlan extends SurfaceMetrics {
  chunks: SurfaceChunk[];
}

interface WorkspaceTitlePlanOptions {
  workspacePath: string;
  workspaceName: string;
  innerWidth: number;
  surfaceWidth: number;
}

interface SurfaceTopFrameOptions {
  width: number;
  left?: SurfaceInlinePlan | SurfaceChunk[];
  status?: string;
  statusEllipsis?: string;
}

interface SurfaceBottomFrameOptions {
  width: number;
  scrollIndicator?: string;
  label?: { full: string; compact: string } | ((width: number) => string);
}

interface SurfaceRowOptions {
  width: number;
  text?: string;
  prefix?: string;
  paddingX?: number;
  ellipsis?: string;
  prefixRole?: SurfaceChunkRole;
  contentRole?: SurfaceChunkRole;
  reserveRightPadding?: boolean;
}

const ANSI_PATTERN = /\x1b\][^\x07]*(?:\x07|\x1b\\)|\x1b\[[0-?]*[ -/]*[@-~]/g;
const CONTROL_PATTERN = /\x1b\][^\x07]*(?:\x07|\x1b\\)|\x1b\[[0-?]*[ -/]*[@-~]/;

function identity(text: string): string {
  return text;
}

function finiteFloor(value: number, fallback: number): number {
  return Number.isFinite(value) ? Math.floor(value) : fallback;
}

function repeat(text: string, width: number): string {
  return text.repeat(Math.max(0, finiteFloor(width, 0)));
}

function chunk(role: SurfaceChunkRole, text: string): SurfaceChunk {
  return { role, text };
}

function stripControls(text: string): string {
  return text.replace(ANSI_PATTERN, "").replace(/[\r\n\t]/g, " ");
}

function truncateSurfaceText(text: string, width: number, ellipsis: string): string {
  if (CONTROL_PATTERN.test(text) || CONTROL_PATTERN.test(ellipsis)) return truncateStyledText(text, width, ellipsis);
  return truncatePlainText(text, width, ellipsis);
}

function safeSurfaceWidth(width: number): number {
  return Math.max(0, finiteFloor(width, 0));
}

export function surfaceMetrics(width: number): SurfaceMetrics {
  const safeWidth = safeSurfaceWidth(width);
  return { safeWidth, innerWidth: Math.max(0, safeWidth - 2) };
}

function surfaceTitleBudget(innerWidth: number): number {
  const safeInnerWidth = Math.max(0, finiteFloor(innerWidth, 0));
  return Math.max(1, Math.min(SURFACE_TITLE_MAX_WIDTH, Math.floor(safeInnerWidth * SURFACE_TITLE_RATIO)));
}

function surfaceChunksWidth(chunks: readonly SurfaceChunk[]): number {
  return chunks.reduce((sum, part) => sum + visibleWidth(part.text), 0);
}

export function renderSurfaceChunks(chunks: readonly SurfaceChunk[], renderers: SurfaceChunkRenderers = {}): string {
  return chunks.map((part) => {
    const renderer = renderers[part.role];
    return renderer ? renderer(part.text, part) : identity(part.text);
  }).join("");
}

function insetLabel(label: string, role: "title" | "status" = "title"): SurfaceInlinePlan {
  const padding = " ".repeat(SURFACE_TITLE_PADDING_X);
  const chunks = [chunk("border", SURFACE_BORDER.horizontal), chunk(role, `${padding}${label}${padding}`)];
  return { chunks, width: surfaceChunksWidth(chunks) };
}

export function planWorkspaceTitle(options: WorkspaceTitlePlanOptions): SurfaceInlinePlan {
  const innerWidth = Math.max(0, finiteFloor(options.innerWidth, 0));
  const surfaceWidth = safeSurfaceWidth(options.surfaceWidth);
  const budget = surfaceTitleBudget(innerWidth);
  const fallbackChunks = surfaceWidth > 0 ? [chunk("border", SURFACE_BORDER.horizontal)] : [];

  if (innerWidth < SURFACE_TITLE_MIN_INNER_WIDTH) {
    return { chunks: fallbackChunks, width: surfaceChunksWidth(fallbackChunks) };
  }

  const labelBudget = Math.max(1, budget - SURFACE_TITLE_PADDING_X * 2);
  const label = formatWorkspaceLabel(options.workspacePath, options.workspaceName || "workspace", labelBudget, surfaceWidth);
  return insetLabel(label);
}

export function planSurfaceStatusBudget(innerWidth: number, leftWidth: number): number {
  const safeInnerWidth = Math.max(0, finiteFloor(innerWidth, 0));
  const safeLeftWidth = Math.max(0, finiteFloor(leftWidth, 0));
  return Math.max(0, safeInnerWidth - safeLeftWidth - SURFACE_STATUS_CHROME_WIDTH);
}

function planSurfaceStatus(status: string | undefined, budget: number, ellipsis = ""): SurfaceStatusPlan {
  const safeBudget = Math.max(0, finiteFloor(budget, 0));
  const raw = status ?? "";
  const text = raw && safeBudget > 0 ? truncateSurfaceText(raw, safeBudget, ellipsis) : "";
  return { text, width: visibleWidth(text) };
}

function resolveInlinePlan(left: SurfaceTopFrameOptions["left"]): SurfaceInlinePlan {
  if (!left) {
    const chunks = [chunk("border", SURFACE_BORDER.horizontal)];
    return { chunks, width: surfaceChunksWidth(chunks) };
  }
  if (Array.isArray(left)) return { chunks: left, width: surfaceChunksWidth(left) };
  return left;
}

export function planSurfaceTopFrame(options: SurfaceTopFrameOptions): SurfaceFramePlan {
  const metrics = surfaceMetrics(options.width);
  if (metrics.safeWidth <= 2) {
    let chunks: SurfaceChunk[] = [];
    if (metrics.safeWidth === 1) chunks = [chunk("border", SURFACE_BORDER.topLeft)];
    if (metrics.safeWidth === 2) chunks = [chunk("border", SURFACE_BORDER.topLeft), chunk("border", SURFACE_BORDER.topRight)];
    return { ...metrics, chunks };
  }

  const left = resolveInlinePlan(options.left);
  const statusBudget = planSurfaceStatusBudget(metrics.innerWidth, left.width);
  const status = planSurfaceStatus(options.status, statusBudget, options.statusEllipsis);
  const statusChromeWidth = status.text ? SURFACE_STATUS_CHROME_WIDTH : 0;
  const fillerWidth = Math.max(0, metrics.innerWidth - left.width - status.width - statusChromeWidth);
  const chunks: SurfaceChunk[] = [
    chunk("border", SURFACE_BORDER.topLeft),
    ...left.chunks,
    chunk("border", repeat(SURFACE_BORDER.horizontal, fillerWidth)),
  ];

  if (status.text) {
    chunks.push(
      chunk("text", " "),
      chunk("status", status.text),
      chunk("text", " "),
      chunk("border", SURFACE_BORDER.horizontal),
    );
  }

  chunks.push(chunk("border", SURFACE_BORDER.topRight));
  return { ...metrics, chunks };
}

export function formatSurfaceScrollIndicator(line: string, width: number): string | undefined {
  const plain = stripControls(line);
  const match = plain.match(/(?:↑|↓) \d+ more/);
  if (!match) return undefined;
  const { innerWidth } = surfaceMetrics(width);
  const indicator = `${repeat(SURFACE_BORDER.horizontal, 3)} ${match[0]} `;
  return truncateSurfaceText(indicator, innerWidth, "");
}

export function planSurfaceBottomFrame(options: SurfaceBottomFrameOptions): SurfaceFramePlan {
  const metrics = surfaceMetrics(options.width);
  if (metrics.safeWidth <= 1) {
    const chunks = metrics.safeWidth === 0 ? [] : [chunk("border", SURFACE_BORDER.bottomLeft)];
    return { ...metrics, chunks };
  }

  const indicator = options.scrollIndicator ? truncateSurfaceText(options.scrollIndicator, metrics.innerWidth, "") : "";
  const indicatorWidth = visibleWidth(indicator);
  const labelBudget = Math.max(0, metrics.innerWidth - indicatorWidth - (indicator ? 1 : 0) - 2 - SURFACE_TITLE_PADDING_X * 2);
  const dynamicLabel = typeof options.label === "function";
  const label = labelBudget > 0 && options.label
    ? typeof options.label === "function" ? truncateSurfaceText(options.label(labelBudget), labelBudget, "…")
      : [options.label.full, options.label.compact].find(text => visibleWidth(text) <= labelBudget)
    : undefined;
  if (label) {
    const left = insetLabel(label, dynamicLabel ? "status" : "title");
    const fillerWidth = metrics.innerWidth - left.width - indicatorWidth;
    const chunks = [
      chunk("border", SURFACE_BORDER.bottomLeft), ...left.chunks,
      chunk("border", repeat(SURFACE_BORDER.horizontal, fillerWidth)),
      ...(indicator ? [chunk("border", indicator)] : []), chunk("border", SURFACE_BORDER.bottomRight),
    ];
    return { ...metrics, chunks };
  }
  const fillerWidth = Math.max(0, metrics.innerWidth - indicatorWidth);
  const chunks = indicator
    ? [
      chunk("border", SURFACE_BORDER.bottomLeft),
      chunk("border", repeat(SURFACE_BORDER.horizontal, fillerWidth)),
      chunk("border", indicator),
      chunk("border", SURFACE_BORDER.bottomRight),
    ]
    : [
      chunk("border", SURFACE_BORDER.bottomLeft),
      chunk("border", repeat(SURFACE_BORDER.horizontal, metrics.innerWidth)),
      chunk("border", SURFACE_BORDER.bottomRight),
    ];
  return { ...metrics, chunks };
}

export function planSurfaceRow(options: SurfaceRowOptions): SurfaceFramePlan {
  const metrics = surfaceMetrics(options.width);
  if (metrics.safeWidth <= 1) {
    const chunks = metrics.safeWidth === 0 ? [] : [chunk("border", SURFACE_BORDER.vertical)];
    return { ...metrics, chunks };
  }

  const paddingX = Math.max(0, finiteFloor(options.paddingX ?? 0, 0));
  const leftPaddingWidth = Math.min(paddingX, metrics.innerWidth);
  const reserveRightPadding = options.reserveRightPadding === true;
  const rightPaddingWidth = reserveRightPadding ? Math.min(paddingX, Math.max(0, metrics.innerWidth - leftPaddingWidth)) : 0;
  const prefixBudget = Math.max(0, metrics.innerWidth - leftPaddingWidth - rightPaddingWidth);
  const prefix = options.prefix ? truncateSurfaceText(options.prefix, prefixBudget, "") : "";
  const prefixWidth = visibleWidth(prefix);
  const contentBudget = Math.max(0, metrics.innerWidth - leftPaddingWidth - prefixWidth - rightPaddingWidth);
  const content = options.text && contentBudget > 0 ? truncateSurfaceText(options.text, contentBudget, options.ellipsis ?? "…") : "";
  const contentWidth = visibleWidth(content);
  const fillerWidth = Math.max(0, metrics.innerWidth - leftPaddingWidth - prefixWidth - contentWidth - rightPaddingWidth);
  const chunks = [
    chunk("border", SURFACE_BORDER.vertical),
    chunk("text", repeat(" ", leftPaddingWidth)),
    chunk(options.prefixRole ?? "dim", prefix),
    chunk(options.contentRole ?? "content", content),
    chunk("text", repeat(" ", fillerWidth + rightPaddingWidth)),
    chunk("border", SURFACE_BORDER.vertical),
  ];
  return { ...metrics, chunks };
}
