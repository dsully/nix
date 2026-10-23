import type { ExtensionContext } from "@earendil-works/pi-coding-agent";
import type { UsageTotals } from "../types.js";

export interface StateModelInputs {
  id?: string;
  name?: string;
  provider?: string;
  contextWindow?: number;
}

export interface StateContextUsageInputs {
  tokens: number | null;
  contextWindow: number;
  percent: number | null;
}

export interface StateThinkingInputs {
  model?: StateModelInputs;
  thinkingLevel: string;
}

export interface StateLifecycleInputs extends StateThinkingInputs {
  cwd: string;
  contextUsage?: StateContextUsageInputs;
}

export interface StateInputs extends StateLifecycleInputs {
  usage: UsageTotals;
}

export interface StateUsageInputs {
  input?: number;
  output?: number;
  cacheRead?: number;
  cacheWrite?: number;
}

export interface StateMessageInputs {
  role?: string;
  stopReason?: string;
  responseId?: unknown;
  toolCallId?: unknown;
  usage?: StateUsageInputs;
}

export interface StateSessionEntry {
  type?: string;
  id?: unknown;
  parentId?: string | null;
  message?: StateMessageInputs;
  usage?: StateUsageInputs;
}

function emptyUsageTotals(): UsageTotals {
  return { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 };
}

export function usageTotalsFromUsage(usage: StateUsageInputs | undefined): UsageTotals {
  return {
    input: usage?.input ?? 0,
    output: usage?.output ?? 0,
    cacheRead: usage?.cacheRead ?? 0,
    cacheWrite: usage?.cacheWrite ?? 0,
  };
}

export function usageTotalsFromMessage(message: StateMessageInputs): UsageTotals {
  if (message.role !== "assistant" && message.role !== "toolResult") return emptyUsageTotals();
  return usageTotalsFromUsage(message.usage);
}

export function usageTotalsFromEntry(entry: StateSessionEntry): UsageTotals {
  if (entry.type === "message" && entry.message) return usageTotalsFromMessage(entry.message);
  if ((entry.type === "usage" || entry.type === "compaction" || entry.type === "branch_summary") && entry.usage)
    return usageTotalsFromUsage(entry.usage);
  return emptyUsageTotals();
}

export function usageTotalsFromEntries(entries: readonly StateSessionEntry[]): UsageTotals {
  const usage = emptyUsageTotals();
  for (const entry of entries) {
    const delta = usageTotalsFromEntry(entry);
    usage.input += delta.input;
    usage.output += delta.output;
    usage.cacheRead += delta.cacheRead;
    usage.cacheWrite += delta.cacheWrite;
  }
  return usage;
}

function modelInputsFromContext(ctx: ExtensionContext): StateModelInputs | undefined {
  const model = ctx.model;
  if (!model) return undefined;
  const name = model.name?.trim();
  return {
    id: model.id,
    ...(name ? { name } : {}),
    provider: model.provider,
    contextWindow: model.contextWindow,
  };
}

function contextUsageInputsFromContext(ctx: ExtensionContext): StateContextUsageInputs | undefined {
  const contextUsage = ctx.getContextUsage();
  return contextUsage
    ? {
        tokens: contextUsage.tokens,
        contextWindow: contextUsage.contextWindow,
        percent: contextUsage.percent,
      }
    : undefined;
}

export function thinkingInputsFromContext(ctx: ExtensionContext, thinkingLevel: string): StateThinkingInputs {
  return {
    model: modelInputsFromContext(ctx),
    thinkingLevel,
  };
}

export function lifecycleInputsFromContext(ctx: ExtensionContext, thinkingLevel: string): StateLifecycleInputs {
  return {
    cwd: ctx.sessionManager.getCwd() || ctx.cwd,
    ...thinkingInputsFromContext(ctx, thinkingLevel),
    contextUsage: contextUsageInputsFromContext(ctx),
  };
}
