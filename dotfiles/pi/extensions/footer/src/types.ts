export type SegmentId = "git" | "throughput" | "context" | "tokens" | "model";
export type WidthMode = "full" | "compact" | "minimal";
export type ActivityKind = "working" | "compaction" | "branchSummary" | "retry";
export interface ActivityStatus {
  readonly kind: ActivityKind;
  render(width: number): string;
}

/**
 * Billed usage accumulated across the whole persisted Pi session: assistant
 * responses, usage-bearing tool results, standalone usage, compactions, and branch summaries.
 */
export interface UsageTotals {
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
}

export interface ModelSpeedMeasurement {
  /** Pi usage.output, including reasoning and tool-call tokens, counted exactly once. */
  outputTokens: number;
  /** Sum of observed request durations, including latency/thinking/hidden retries, excluding tool/UI waits. */
  elapsedMs: number;
  tokensPerSecond: number;
}

export interface FooterState {
  workspace: {
    name: string;
    path: string;
  };
  branch: string | null;
  providers: {
    availableCount: number;
  };
  model: {
    id?: string;
    provider?: string;
    displayName?: string;
    thinking: string;
  };
  context: {
    tokens: number | null;
    window: number;
    percent: number | null;
  };
  usage: UsageTotals;
  throughput: {
    lastRun: ModelSpeedMeasurement | null;
    currentRun: ModelSpeedMeasurement | null;
  };
  version: number;
}

export interface Rgb {
  r: number;
  g: number;
  b: number;
}

export type SegmentTone = "normal" | "warning" | "error";

export interface SegmentData {
  /** Semantic emphasis, independent of the chosen display text. */
  tone?: SegmentTone;
  primary: string;
  secondary?: string;
  display?: {
    full?: string;
    compact?: string;
    minimal?: string;
  };
  /** Ordered shorter labels, followed by a name that can be middle-ellipsized. */
  fit?: {
    alternatives: readonly string[];
    name: { prefix: string; value: string; suffix: string };
  };
}

export interface SegmentRenderContext {
  state: FooterState;
  widthMode: WidthMode;
  showProvider: boolean;
}

export interface SegmentRenderResult {
  id: SegmentId;
  text: string;
  tone: SegmentTone;
  /** Returns a meaningful label within the available columns, or no fit. */
  fit?: (width: number) => string | undefined;
}

export interface SegmentDefinition {
  id: SegmentId;
  icon: string;
  iconSpacing?: number;
  collect(ctx: SegmentRenderContext): SegmentData | undefined;
}
