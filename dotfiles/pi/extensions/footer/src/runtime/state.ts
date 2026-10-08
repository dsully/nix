import { displayDirectory, shortenModel } from "../surface/format.js";
import type { StateInputs } from "./snapshot.js";
import type { FooterState, ModelSpeedMeasurement, UsageTotals } from "../types.js";

export function createInitialState(inputs: StateInputs, branch: string | null): FooterState {
  const state: FooterState = {
    workspace: {
      name: displayDirectory(inputs.cwd),
      path: inputs.cwd,
    },
    branch,
    providers: {
      availableCount: inputs.availableProviderCount,
    },
    model: {
      id: inputs.model?.id,
      provider: inputs.model?.provider,
      displayName: shortenModel(inputs.model?.id, inputs.model?.name),
      thinking: inputs.thinkingLevel,
    },
    context: {
      tokens: null,
      window: inputs.model?.contextWindow ?? 0,
      percent: null,
    },
    usage: inputs.usage,
    throughput: {
      lastRun: null,
      currentRun: null,
    },
    version: 0,
  };
  refreshContextUsage(state, inputs);
  return state;
}

function touch(state: FooterState): void {
  state.version++;
}

function usageTotalsEqual(a: UsageTotals, b: UsageTotals): boolean {
  return a.input === b.input && a.output === b.output && a.cacheRead === b.cacheRead && a.cacheWrite === b.cacheWrite;
}

function modelSpeedEqual(a: ModelSpeedMeasurement | null, b: ModelSpeedMeasurement | null): boolean {
  if (a === b) return true;
  if (!a || !b) return false;
  return (
    a.outputTokens === b.outputTokens &&
    a.elapsedMs === b.elapsedMs &&
    a.tokensPerSecond === b.tokensPerSecond
  );
}

export function setLastRunModelSpeed(state: FooterState, next: ModelSpeedMeasurement | null): boolean {
  if (modelSpeedEqual(state.throughput.lastRun, next)) return false;
  state.throughput.lastRun = next;
  touch(state);
  return true;
}

export function setCurrentRunModelSpeed(state: FooterState, next: ModelSpeedMeasurement | null): boolean {
  if (modelSpeedEqual(state.throughput.currentRun, next)) return false;
  state.throughput.currentRun = next;
  touch(state);
  return true;
}

export function clearCurrentRunModelSpeed(state: FooterState): boolean {
  return setCurrentRunModelSpeed(state, null);
}

export function setUsageTotals(state: FooterState, usage: UsageTotals): boolean {
  if (usageTotalsEqual(state.usage, usage)) return false;
  state.usage = usage;
  touch(state);
  return true;
}

export function addUsageTotals(state: FooterState, delta: UsageTotals): boolean {
  if (delta.input === 0 && delta.output === 0 && delta.cacheRead === 0 && delta.cacheWrite === 0) return false;
  state.usage = {
    input: state.usage.input + delta.input,
    output: state.usage.output + delta.output,
    cacheRead: state.usage.cacheRead + delta.cacheRead,
    cacheWrite: state.usage.cacheWrite + delta.cacheWrite,
  };
  touch(state);
  return true;
}

export function setProviderCount(state: FooterState, availableCount: number): boolean {
  if (state.providers.availableCount === availableCount) return false;
  state.providers.availableCount = availableCount;
  touch(state);
  return true;
}

export function refreshWorkspace(state: FooterState, inputs: Pick<StateInputs, "cwd">): boolean {
  const cwd = inputs.cwd;
  if (state.workspace.path === cwd) return false;
  state.workspace = {
    name: displayDirectory(cwd),
    path: cwd,
  };
  touch(state);
  return true;
}

export function setBranch(state: FooterState, branch: string | null): boolean {
  if (state.branch === branch) return false;
  state.branch = branch;
  touch(state);
  return true;
}

export function refreshContextUsage(state: FooterState, inputs: Pick<StateInputs, "contextUsage" | "model">): boolean {
  const usage = inputs.contextUsage;
  const tokens = usage?.tokens ?? null;
  const window = usage?.contextWindow ?? inputs.model?.contextWindow ?? 0;
  const percent = usage?.percent ?? null;
  if (state.context.tokens === tokens && state.context.window === window && state.context.percent === percent) return false;
  state.context.tokens = tokens;
  state.context.window = window;
  state.context.percent = percent;
  touch(state);
  return true;
}

export function refreshModel(state: FooterState, inputs: Pick<StateInputs, "model" | "thinkingLevel">): boolean {
  const id = inputs.model?.id;
  const provider = inputs.model?.provider;
  const displayName = shortenModel(inputs.model?.id, inputs.model?.name);
  // Selection metadata does not own Context: virtual and physical limits can differ.
  if (
    state.model.id === id &&
    state.model.provider === provider &&
    state.model.displayName === displayName &&
    state.model.thinking === inputs.thinkingLevel
  ) {
    return false;
  }
  state.model.id = id;
  state.model.provider = provider;
  state.model.displayName = displayName;
  state.model.thinking = inputs.thinkingLevel;
  touch(state);
  return true;
}
