import type { ExtensionContext, MessageEndEvent, SessionCompactEvent } from "@earendil-works/pi-coding-agent";
import {
  contextUsageInputsFromContext,
  lifecycleInputsFromContext,
  thinkingInputsFromContext,
  usageTotalsFromEntries,
  usageTotalsFromEntry,
  usageTotalsFromMessage,
  type StateInputs,
  type StateLifecycleInputs,
  type StateMessageInputs,
  type StateSessionEntry,
} from "./snapshot.js";
import {
  addUsageTotals,
  createInitialState,
  refreshContextUsage,
  refreshModel,
  refreshWorkspace,
  setBranch,
  setUsageTotals,
} from "./state.js";
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
  requestRender(): void;
  readStatus(): string | undefined;
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

export class RuntimeRefreshSession {
  private state?: FooterState;
  private appliedUsageObjects = new WeakSet<object>();
  private appliedUsageKeys = new Set<string>();
  private seenEntryIds = new Set<string>();

  constructor(private readonly host: RuntimeRefreshSessionHost) {}

  getState(): FooterState | undefined {
    return this.state;
  }

  private readStateInputs(ctx: ExtensionContext): StateInputs {
    const entries = ctx.sessionManager.getEntries();
    this.seenEntryIds = new Set(entries.map((entry) => entry.id));
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
      ...lifecycleInputsFromContext(ctx, this.host.getThinkingLevel(), this.host.readStatus()),
      usage: usageTotalsFromEntries(entries),
    };
  }

  private resetAccumulators(): void {
    this.seenEntryIds.clear();
    this.appliedUsageObjects = new WeakSet<object>();
    this.appliedUsageKeys = new Set<string>();
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
    // Rendered on every frame, so the reading is never one event behind the
    // extension that publishes it.
    refreshContextUsage(this.state, {
      contextUsage: contextUsageInputsFromContext(ctx, this.host.readStatus()),
      model: ctx.model,
    });
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
    if (message.role === "assistant" && typeof message.responseId === "string" && message.responseId)
      return `assistant:${message.responseId}`;
    if (message.role === "toolResult" && typeof message.toolCallId === "string" && message.toolCallId)
      return `toolResult:${message.toolCallId}`;
    return undefined;
  }

  private entryUsageKey(entry: StateSessionEntry): string | undefined {
    return typeof entry.id === "string" && entry.id ? `${entry.type ?? "entry"}:${entry.id}` : undefined;
  }

  private applyLifecycleSnapshot(inputs: StateLifecycleInputs, plan: RefreshPlan, usage?: UsageTotals): boolean {
    if (!this.state) return false;
    let changed = false;
    if (plan.refreshWorkspace) changed = refreshWorkspace(this.state, inputs) || changed;
    if (plan.refreshModel) changed = refreshModel(this.state, inputs) || changed;
    if (plan.refreshUsageTotals && usage) changed = setUsageTotals(this.state, usage) || changed;
    if (plan.refreshContext) changed = refreshContextUsage(this.state, inputs) || changed;
    return changed;
  }

  private applyRefreshPlan(ctx: ExtensionContext, plan: RefreshPlan): boolean {
    if (!this.state || plan.snapshot === "none") return false;

    if (plan.snapshot === "thinking") {
      const inputs = thinkingInputsFromContext(ctx, this.host.getThinkingLevel());
      return plan.refreshModel ? refreshModel(this.state, inputs) : false;
    }

    if (plan.snapshot === "reliable") {
      const inputs = this.readStateInputs(ctx);
      return this.applyLifecycleSnapshot(inputs, plan, inputs.usage);
    }

    return this.applyLifecycleSnapshot(
      lifecycleInputsFromContext(ctx, this.host.getThinkingLevel(), this.host.readStatus()),
      plan,
    );
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
    this.refresh(ctx, LIFECYCLE_MODEL);
  }

  /** Also covers turn_end, agent_end and tool_execution_end. */
  lifecycle(ctx: ExtensionContext): void {
    this.refresh(ctx, LIFECYCLE_NO_MODEL);
  }

  sessionTree(ctx: ExtensionContext): void {
    this.refresh(ctx, RELIABLE_MODEL);
  }

  messageEnd(event: RuntimeMessageEndInput, ctx: ExtensionContext): void {
    const message = event.message;
    const hadState = this.state !== undefined;
    const delta = usageTotalsFromMessage(message);
    const plan =
      message.role === "assistant"
        ? LIFECYCLE_NO_MODEL
        : message.role === "toolResult" && !this.usageTotalsAreZero(delta)
          ? USAGE_MESSAGE_END
          : ENSURE_ONLY;
    this.refresh(ctx, plan, () => hadState && this.applyUsageDelta(message, delta, this.messageUsageKey(message)));
  }

  sessionCompact(event: RuntimeSessionCompactInput, ctx: ExtensionContext): void {
    const hadState = this.state !== undefined;
    const entry = event.compactionEntry;
    const delta = usageTotalsFromEntry(entry);
    this.refresh(ctx, LIFECYCLE_MODEL, () => hadState && this.applyUsageDelta(entry, delta, this.entryUsageKey(entry)));
  }

  agentSettled(ctx: ExtensionContext): void {
    if (!this.state) return;
    let changed = this.syncPersistedUsage(ctx);
    changed =
      refreshContextUsage(this.state, {
        contextUsage: contextUsageInputsFromContext(ctx, this.host.readStatus()),
        model: ctx.model,
      }) || changed;
    if (changed) this.host.requestRender();
  }

  branchChanged(branch: string | null): void {
    if (this.state && setBranch(this.state, branch)) this.host.requestRender();
  }
}
