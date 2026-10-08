import { stripTerminalSequences, visibleWidth } from "@earendil-works/pi-tui";
import { truncateStyledText } from "./text.js";
import {
  planSurfaceBottomFrame,
  planSurfaceRow,
  planSurfaceStatusBudget,
  planSurfaceTopFrame,
  planWorkspaceTitle,
  renderSurfaceChunks,
  surfaceMetrics,
  SURFACE_AUTOCOMPLETE_INDENT,
  SURFACE_CONTENT_PADDING_X,
} from "./layout.js";
import type { FooterStyles } from "../theme.js";
import type { ActivityStatus, FooterState } from "../types.js";

export const STASH_SHORTCUT = "alt+s";
const DRAFT_LABEL = "\uf48d";

export interface InputSurfaceFrameMetrics {
  safeWidth: number;
  innerWidth: number;
  editorContentWidth: number;
  autocompleteIndent: number;
}

export interface InputSurfaceFrameInput {
  state: FooterState;
  width: number;
  styles: FooterStyles;
  lines: readonly string[];
  focused: boolean;
  activity?: ActivityStatus;
  topScrollIndicator?: string;
  bottomScrollIndicator?: string;
  hasDraft?: boolean;
  status(budget: number): string;
}

// Keeps SGR (CSI final byte `m`) so extension-colored working messages survive; drops OSC/APC and other CSI.
function stripNonSgrSequences(text: string): string {
  return text
    .replace(/\x1b[\]_][^\x07]*(?:\x07|\x1b\\)/g, "")
    .replace(/\x1b\[[0-?]*[ -/]*[@-ln-~]/g, "");
}

function identity(text: string): string {
  return text;
}

function stripControlsPreservingSpaces(text: string): string {
  return text
    .replace(/\x1b\][^\x07]*(?:\x07|\x1b\\)/g, "")
    .replace(/\x1b\[[0-?]*[ -/]*[@-~]/g, "")
    .replace(/[\r\n\t]/g, " ");
}

function resolveStatus(input: InputSurfaceFrameInput, budget: number): string {
  const status = input.status(budget);
  return status && !input.focused ? input.styles.dim(stripControlsPreservingSpaces(status)) : status;
}

function planTopFrame(input: InputSurfaceFrameInput, metrics: InputSurfaceFrameMetrics) {
  const scrollIndicator = input.topScrollIndicator;
  const left = scrollIndicator
    ? { chunks: [{ role: "border" as const, text: scrollIndicator }], width: visibleWidth(scrollIndicator) }
    : planWorkspaceTitle({
      workspacePath: input.state.workspace.path,
      workspaceName: input.state.workspace.name,
      innerWidth: metrics.innerWidth,
      surfaceWidth: metrics.safeWidth,
    });
  const statusBudget = planSurfaceStatusBudget(metrics.innerWidth, left.width);
  return planSurfaceTopFrame({ width: metrics.safeWidth, left, status: resolveStatus(input, statusBudget) });
}

function renderTopFrame(input: InputSurfaceFrameInput, plan: ReturnType<typeof planSurfaceTopFrame>): string {
  const border = input.focused ? input.styles.border : input.styles.dim;
  const title = input.focused ? input.styles.path : input.styles.dim;
  const rendered = renderSurfaceChunks(plan.chunks, { title, border, dim: border });
  return truncateStyledText(rendered, plan.safeWidth, border("…"));
}

function renderEditorRow(input: InputSurfaceFrameInput, text: string, width: number): string {
  return renderSurfaceChunks(
    planSurfaceRow({ width, text, paddingX: SURFACE_CONTENT_PADDING_X, reserveRightPadding: true, ellipsis: "" }).chunks,
    { border: input.focused ? input.styles.border : input.styles.dim, content: identity, text: identity },
  );
}

function planBottomFrame(input: InputSurfaceFrameInput, width: number) {
  const activity = input.activity;
  const activityStyle = !input.focused ? input.styles.dim : activity?.kind === "retry" ? input.styles.warn : input.styles.title;
  const strip = input.focused ? stripNonSgrSequences : stripTerminalSequences;
  return planSurfaceBottomFrame({
    width, scrollIndicator: input.bottomScrollIndicator,
    label: activity ? budget => activityStyle(truncateStyledText(strip(activity.render(budget)).replace(/[\r\n\t]/g, " "), budget, "…"))
      : input.hasDraft ? { full: `${DRAFT_LABEL} · ${STASH_SHORTCUT}`, compact: DRAFT_LABEL } : undefined,
  });
}

function renderBottomFrame(input: InputSurfaceFrameInput, plan: ReturnType<typeof planBottomFrame>): string {
  const border = input.focused ? input.styles.border : input.styles.dim;
  const title = input.focused ? input.styles.title : input.styles.dim;
  return renderSurfaceChunks(plan.chunks, { status: identity, title, border });
}

export function measureInputSurfaceFrame(width: number): InputSurfaceFrameMetrics {
  const { safeWidth, innerWidth } = surfaceMetrics(width);
  return {
    safeWidth,
    innerWidth,
    editorContentWidth: Math.max(1, safeWidth - 2 - SURFACE_CONTENT_PADDING_X * 2),
    autocompleteIndent: Math.min(SURFACE_AUTOCOMPLETE_INDENT, Math.max(0, safeWidth - 1)),
  };
}

export function renderInputSurfaceFrame(input: InputSurfaceFrameInput): string[] {
  const metrics = measureInputSurfaceFrame(input.width);
  const lines = [renderTopFrame(input, planTopFrame(input, metrics))];
  for (const line of input.lines.length > 0 ? input.lines : [""]) lines.push(renderEditorRow(input, line, metrics.safeWidth));
  lines.push(renderBottomFrame(input, planBottomFrame(input, metrics.safeWidth)));
  return lines;
}
