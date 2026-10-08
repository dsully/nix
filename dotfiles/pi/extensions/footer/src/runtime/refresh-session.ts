import type { ExtensionContext, MessageEndEvent, SessionCompactEvent } from "@earendil-works/pi-coding-agent";
import { lifecycleInputsFromContext, thinkingInputsFromContext, usageTotalsFromEntries, usageTotalsFromEntry, usageTotalsFromMessage, type StateInputs, type StateLifecycleInputs, type StateMessageInputs, type StateSessionEntry } from "./snapshot.js";
import {
  addUsageTotals,
  clearCurrentRunModelSpeed,
  createInitialState,
  refreshContextUsage,
  refreshModel,
  refreshWorkspace,
  setBranch,
  setCurrentRunModelSpeed,
  setLastRunModelSpeed,
  setProviderCount,
  setUsageTotals,
} from "./state.js";
import { ModelSpeedRunTracker, type ModelSpeedStateIntent } from "./throughput-run-tracker.js";
import type { FooterState, UsageTotals } from "../types.js";

export interface RuntimeMessageEndInput {
  type?: MessageEndEvent["type"];
  message: StateMessageInputs;
}

export interface RuntimeSessionCompactInput {
  type?: SessionCompactEvent["type"];
  compactionEntry: StateSessionEntry;
  willRetry?: boolean;
}

export interface RuntimeRefreshSessionHost {
  getThinkingLevel(): string;
  getBranch(): string | null;
  nowMs(): number;
  requestRender(): void;
}

type SnapshotMode = "none" | "reliable" | "lifecycle" | "thinking";

interface RefreshPlan {
  snapshot: SnapshotMode;
  refreshWorkspace: boolean;
  refreshModel: boolean;
  refreshUsageTotals: boolean;
  refreshContext: boolean;
  render: boolean;
}

const ENSURE_ONLY: RefreshPlan = {
  snapshot: "none",
  refreshWorkspace: false,
  refreshModel: false,
  refreshUsageTotals: false,
  refreshContext: false,
  render: false,
};

const LIFECYCLE_MODEL: RefreshPlan = {
  snapshot: "lifecycle",
  refreshWorkspace: true,
  refreshModel: true,
  refreshUsageTotals: false,
  refreshContext: true,
  render: true,
};

const RELIABLE_MODEL: RefreshPlan = { ...LIFECYCLE_MODEL, snapshot: "reliable", refreshUsageTotals: true };
const LIFECYCLE_NO_MODEL: RefreshPlan = { ...LIFECYCLE_MODEL, refreshModel: false };
const USAGE_MESSAGE_END: RefreshPlan = { ...ENSURE_ONLY, render: true };
const THINKING_LEVEL_SELECT: RefreshPlan = { ...ENSURE_ONLY, snapshot: "thinking", refreshModel: true, render: true };

function applyModelSpeedIntent(state: FooterState, intent: ModelSpeedStateIntent): boolean {
  switch (intent.kind) {
    case "none":
      return false;
    case "set-current-run":
      return setCurrentRunModelSpeed(state, intent.currentRun);
    case "clear-current-run":
      return clearCurrentRunModelSpeed(state);
    case "set-last-run-and-clear-current-run": {
      const lastRunChanged = setLastRunModelSpeed(state, intent.lastRun);
      const currentRunChanged = clearCurrentRunModelSpeed(state);
      return lastRunChanged || currentRunChanged;
    }
  }
}

export class RuntimeRefreshSession {
  private state?: FooterState;
  private appliedUsageObjects = new WeakSet<object>();
  private appliedUsageKeys = new Set<string>();
  private seenEntryIds = new Set<string>();
  private readonly modelSpeedTracker = new ModelSpeedRunTracker();

  constructor(private readonly host: RuntimeRefreshSessionHost) { }

  getState(): FooterState | undefined {
    return this.state;
  }

  private readStateInputs(ctx: ExtensionContext): StateInputs {
    const entries = ctx.sessionManager.getEntries();
    this.seenEntryIds = new Set(entries.map(entry => entry.id));
    // Reliable snapshots have already billed these entries. Late event delivery
    // must use the same deduplication ledger as incremental persistence reads.
    for (const entry of entries) {
      if (entry.type === "message" && entry.message) {
        this.claimUsageDelta(entry.message, this.messageUsageKey(entry.message));
      } else if (entry.type === "usage" || entry.type === "compaction" || entry.type === "branch_summary") {
        this.claimUsageDelta(entry, this.entryUsageKey(entry));
      }
    }
    return {
      ...lifecycleInputsFromContext(ctx, this.host.getThinkingLevel()),
      usage: usageTotalsFromEntries(entries),
    };
  }

  private resetAccumulators(): void {
    this.seenEntryIds.clear();
    this.appliedUsageObjects = new WeakSet<object>();
    this.appliedUsageKeys = new Set<string>();
    this.modelSpeedTracker.reset();
  }

  private resetState(ctx: ExtensionContext): FooterState {
    this.state = createInitialState(this.readStateInputs(ctx), this.host.getBranch());
    return this.state;
  }

  sessionStart(ctx: ExtensionContext): FooterState {
    this.resetAccumulators();
    return this.resetState(ctx);
  }

  sessionShutdown(): void {
    this.resetAccumulators();
  }

  ensureState(ctx: ExtensionContext): FooterState {
    if (!this.state) return this.resetState(ctx);
    this.syncPersistedUsage(ctx);
    return this.state;
  }

  /** Background usage and boundary summaries can be persisted without a matching event. */
  private syncPersistedUsage(ctx: ExtensionContext): boolean {
    let changed = false;
    let id = ctx.sessionManager.getLeafId();
    // Unchanged frames are O(1); only newly appended ancestors are inspected.
    while (id && !this.seenEntryIds.has(id)) {
      const entry: StateSessionEntry | undefined = ctx.sessionManager.getEntry(id);
      if (!entry) break;
      this.seenEntryIds.add(id);
      if (entry.type === "usage" || entry.type === "compaction" || entry.type === "branch_summary") {
        changed = this.applyUsageDelta(entry, usageTotalsFromEntry(entry), this.entryUsageKey(entry)) || changed;
      }
      id = entry.parentId ?? null;
    }
    return changed;
  }

  private usageTotalsAreZero(delta: UsageTotals): boolean {
    return delta.input === 0 && delta.output === 0 && delta.cacheRead === 0 && delta.cacheWrite === 0;
  }

  private claimUsageDelta(source: object, key: string | undefined): boolean {
    if (key) {
      if (this.appliedUsageKeys.has(key)) return false;
      this.appliedUsageKeys.add(key);
      return true;
    }
    if (this.appliedUsageObjects.has(source)) return false;
    this.appliedUsageObjects.add(source);
    return true;
  }

  private applyUsageDelta(source: object, delta: UsageTotals, key?: string): boolean {
    if (!this.state || this.usageTotalsAreZero(delta) || !this.claimUsageDelta(source, key)) return false;
    return addUsageTotals(this.state, delta);
  }

  private messageUsageKey(message: StateMessageInputs): string | undefined {
    if (message.role === "assistant" && typeof message.responseId === "string" && message.responseId) return `assistant:${message.responseId}`;
    if (message.role === "toolResult" && typeof message.toolCallId === "string" && message.toolCallId) return `toolResult:${message.toolCallId}`;
    return undefined;
  }

  private entryUsageKey(entry: StateSessionEntry): string | undefined {
    return typeof entry.id === "string" && entry.id ? `${entry.type ?? "entry"}:${entry.id}` : undefined;
  }

  private applyLifecycleSnapshot(inputs: StateLifecycleInputs, plan: RefreshPlan, usage?: UsageTotals): boolean {
    if (!this.state) return false;
    let changed = false;
    if (plan.refreshWorkspace) changed = refreshWorkspace(this.state, inputs) || changed;
    changed = setProviderCount(this.state, inputs.availableProviderCount) || changed;
    if (plan.refreshModel) changed = refreshModel(this.state, inputs) || changed;
    if (plan.refreshUsageTotals && usage) changed = setUsageTotals(this.state, usage) || changed;
    if (plan.refreshContext) changed = refreshContextUsage(this.state, inputs) || changed;
    return changed;
  }

  private applyRefreshPlan(ctx: ExtensionContext, plan: RefreshPlan): boolean {
    if (!this.state || plan.snapshot === "none") return false;

    if (plan.snapshot === "thinking") {
      const inputs = thinkingInputsFromContext(ctx, this.host.getThinkingLevel());
      let changed = setProviderCount(this.state, inputs.availableProviderCount);
      if (plan.refreshModel) changed = refreshModel(this.state, inputs) || changed;
      return changed;
    }

    if (plan.snapshot === "reliable") {
      const inputs = this.readStateInputs(ctx);
      return this.applyLifecycleSnapshot(inputs, plan, inputs.usage);
    }

    return this.applyLifecycleSnapshot(lifecycleInputsFromContext(ctx, this.host.getThinkingLevel()), plan);
  }

  private refresh(ctx: ExtensionContext, plan: RefreshPlan, beforeRender?: () => boolean): void {
    let changed = false;
    if (!this.state) {
      this.ensureState(ctx);
      changed = true;
    }
    changed = this.applyRefreshPlan(ctx, plan) || changed;
    changed = beforeRender?.() === true || changed;
    if (plan.render && changed) this.host.requestRender();
  }

  modelSelect(ctx: ExtensionContext): void {
    this.refresh(ctx, LIFECYCLE_MODEL);
  }

  thinkingLevelSelect(ctx: ExtensionContext): void {
    this.refresh(ctx, THINKING_LEVEL_SELECT);
  }

  turnStart(ctx: ExtensionContext): void {
    this.modelSpeedTracker.turnStart();
    this.refresh(ctx, LIFECYCLE_MODEL);
  }

  /** Also covers turn_end, agent_end and tool_execution_end. */
  lifecycle(ctx: ExtensionContext): void {
    this.refresh(ctx, LIFECYCLE_NO_MODEL);
  }

  sessionTree(ctx: ExtensionContext): void {
    this.refresh(ctx, RELIABLE_MODEL);
  }

  providerRequest(): void {
    this.modelSpeedTracker.requestStart(() => this.host.nowMs());
  }

  uiPromptStart(): void {
    this.modelSpeedTracker.uiPromptStart(() => this.host.nowMs());
  }

  uiPromptEnd(): void {
    this.modelSpeedTracker.uiPromptEnd(() => this.host.nowMs());
  }

  messageEnd(event: RuntimeMessageEndInput, ctx: ExtensionContext): void {
    const message = event.message;
    const hadState = this.state !== undefined;
    const delta = usageTotalsFromMessage(message);
    const modelSpeedIntent = this.modelSpeedTracker.messageEnd(message, () => this.host.nowMs());
    const plan = message.role === "assistant"
      ? LIFECYCLE_NO_MODEL
      : message.role === "toolResult" && !this.usageTotalsAreZero(delta)
        ? USAGE_MESSAGE_END
        : ENSURE_ONLY;
    this.refresh(ctx, plan, () => {
      let changed = false;
      if (hadState) changed = this.applyUsageDelta(message, delta, this.messageUsageKey(message)) || changed;
      if (this.state) changed = applyModelSpeedIntent(this.state, modelSpeedIntent) || changed;
      return changed;
    });
  }

  sessionCompact(event: RuntimeSessionCompactInput, ctx: ExtensionContext): void {
    const hadState = this.state !== undefined;
    const entry = event.compactionEntry;
    const delta = usageTotalsFromEntry(entry);
    const modelSpeedIntent = this.modelSpeedTracker.compactionRetry(event.willRetry === true);
    this.refresh(ctx, LIFECYCLE_MODEL, () => {
      let changed = false;
      if (hadState) changed = this.applyUsageDelta(entry, delta, this.entryUsageKey(entry)) || changed;
      if (this.state) changed = applyModelSpeedIntent(this.state, modelSpeedIntent) || changed;
      return changed;
    });
  }

  agentStart(): void {
    const intent = this.modelSpeedTracker.start();
    if (this.state && applyModelSpeedIntent(this.state, intent)) this.host.requestRender();
  }

  agentSettled(ctx: ExtensionContext): void {
    const intent = this.modelSpeedTracker.settle();
    if (!this.state) return;
    let changed = this.syncPersistedUsage(ctx);
    changed = refreshContextUsage(this.state, { contextUsage: ctx.getContextUsage() ?? undefined, model: ctx.model }) || changed;
    changed = applyModelSpeedIntent(this.state, intent) || changed;
    if (changed) this.host.requestRender();
  }

  branchChanged(branch: string | null): void {
    if (this.state && setBranch(this.state, branch)) this.host.requestRender();
  }
}
