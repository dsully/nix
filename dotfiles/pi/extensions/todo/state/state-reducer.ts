import type { Task, TaskAction, TaskMutationParams, TaskStatus } from "../tool/types.js";
import { isTransitionValid } from "./invariants.js";
import type { TaskState } from "./state.js";
import { detectCycle, liveDescendants } from "./task-graph.js";

/**
 * Reducer outcome. Closed tagged union — adding a new action requires extending
 * this union AND the response-envelope's `formatContent` switch (compiler-
 * enforced exhaustive). Mirrors the `Effect` pattern in
 * `packages/rpiv-ask-user-question/state/state-reducer.ts:14-30`.
 *
 * `error` carries the message in-band so callers can pattern-match on
 * `op.kind === "error"` without a side-channel boolean.
 */
export type Op =
  | { kind: "create"; taskIds: number[] }
  | { kind: "update"; id: number; fromStatus: TaskStatus; toStatus: TaskStatus; changed: boolean }
  | { kind: "delete"; id: number; subject: string; promoted: number[] }
  | { kind: "list"; statusFilter?: TaskStatus; includeDeleted: boolean }
  | { kind: "get"; task: Task }
  | { kind: "clear"; count: number }
  | { kind: "error"; message: string };

export interface ApplyResult {
  state: TaskState;
  op: Op;
}

/**
 * True when `op` changed the task state — the calls whose post-commit snapshot
 * must be persisted for replay. Reads (`list`/`get`), failures, and a no-effect
 * `update` leave state untouched. Exhaustive over `Op` (compiler-enforced), so a
 * new action must decide here whether it persists.
 */
export function changesState(op: Op): boolean {
  switch (op.kind) {
    case "create":
    case "delete":
    case "clear":
      return true;
    case "update":
      return op.changed;
    case "list":
    case "get":
    case "error":
      return false;
  }
}

function errorResult(state: TaskState, message: string): ApplyResult {
  return { state, op: { kind: "error", message } };
}

/** Per-task create fields: on a batch they belong to each `tasks[]` item. */
const BATCH_ITEM_FIELDS = ["description", "activeForm", "blockedBy", "owner", "metadata"] as const;

function asCreateItem(value: unknown): TaskMutationParams | undefined {
  if (typeof value !== "object" || value === null || Array.isArray(value)) return undefined;
  return value as TaskMutationParams;
}

function buildCreatedTask(id: number, spec: TaskMutationParams, subject: string, parentId: number | undefined): Task {
  const newTask: Task = {
    id,
    subject,
    status: "pending",
  };
  if (spec.description) newTask.description = spec.description;
  if (spec.activeForm) newTask.activeForm = spec.activeForm;
  if (parentId !== undefined) newTask.parentId = parentId;
  if (spec.blockedBy?.length) newTask.blockedBy = [...spec.blockedBy];
  if (spec.owner) newTask.owner = spec.owner;
  if (spec.metadata) newTask.metadata = { ...spec.metadata };
  return newTask;
}

function validateCreateBlockedBy(
  state: TaskState,
  blockedBy: number[] | undefined,
  siblingIds: ReadonlySet<number>,
): string | undefined {
  if (!blockedBy?.length) return undefined;
  for (const dep of blockedBy) {
    if (siblingIds.has(dep)) {
      return `blockedBy: #${dep} is another item in this batch; create the prerequisite first, then the dependent with blockedBy`;
    }
    const depTask = state.tasks.find((t) => t.id === dep);
    if (!depTask) return `blockedBy: #${dep} not found`;
    if (depTask.status === "deleted") return `blockedBy: #${dep} is deleted`;
  }
  return undefined;
}

/**
 * A parent must be live and unfinished. Completion is one-way, so an unfinished child under a
 * completed parent could never let that parent's subtree be consistent again.
 */
function validateParent(
  state: TaskState,
  parentId: number | undefined,
  siblingIds: ReadonlySet<number>,
  subtreeDone = false,
): string | undefined {
  if (parentId === undefined) return undefined;
  if (siblingIds.has(parentId)) {
    return `parentId: #${parentId} is another item in this batch; create the parent first, then its subtasks with parentId`;
  }
  const parent = state.tasks.find((t) => t.id === parentId);
  if (!parent) return `parentId: #${parentId} not found`;
  if (parent.status === "deleted") return `parentId: #${parentId} is deleted`;
  if (parent.status === "completed" && !subtreeDone) return `parentId: #${parentId} is completed`;
  return undefined;
}

/** Re-parent the live children of a just-deleted task onto its parent, so no live task hangs off a tombstone. */
function promoteChildren(tasks: Task[], deleted: Task): number[] {
  const promoted: number[] = [];
  for (const [i, t] of tasks.entries()) {
    if (t.parentId !== deleted.id || t.status === "deleted") continue;
    const moved: Task = { ...t };
    if (deleted.parentId === undefined) delete moved.parentId;
    else moved.parentId = deleted.parentId;
    tasks[i] = moved;
    promoted.push(t.id);
  }
  return promoted;
}

function sameNumberList(a: number[] | undefined, b: number[] | undefined): boolean {
  const x = a ?? [];
  const y = b ?? [];
  return x.length === y.length && x.every((v, i) => v === y[i]);
}

function sameRecord(a: Record<string, unknown> | undefined, b: Record<string, unknown> | undefined): boolean {
  return JSON.stringify(a ?? null) === JSON.stringify(b ?? null);
}

/**
 * Did this `update` change anything? Compares the task before/after the params
 * are applied. A no-effect update — `status` set to its current value, or any
 * field re-sent unchanged — returns false, letting the response envelope say
 * "No change" instead of "Updated #N". Without this, a no-op update is
 * indistinguishable from a real mutation, which can drive a model to re-issue
 * the same call in a loop.
 *
 * blockedBy is order-sensitive (the reducer preserves insertion order);
 * metadata round-trips through JSON persistence, so JSON-equality is the
 * operative notion of "changed".
 */
function taskChanged(before: Task, after: Task): boolean {
  return (
    before.subject !== after.subject ||
    before.status !== after.status ||
    before.description !== after.description ||
    before.activeForm !== after.activeForm ||
    before.owner !== after.owner ||
    before.parentId !== after.parentId ||
    !sameNumberList(before.blockedBy, after.blockedBy) ||
    !sameRecord(before.metadata, after.metadata)
  );
}

/**
 * Pure reducer: (state, action, params) → (state, op). The response envelope (`tool/response-envelope.ts`) owns
 * formatting, the store (`state/store.ts`) owns commit.
 *
 * Validation is in-line: structural guards (`subject required`, `id required`,
 * `at least one mutable field`) plus state-aware checks (transition legality,
 * dangling/deleted blockedBy, self-block, cycles). Decision: validation stays
 * in-reducer.
 */
export function applyTaskMutation(state: TaskState, action: TaskAction, params: TaskMutationParams): ApplyResult {
  switch (action) {
    case "create": {
      const batch = params.tasks;

      if (Array.isArray(batch) && params.subject !== undefined) {
        return errorResult(state, "create requires subject or tasks[], not both");
      }

      if (Array.isArray(batch)) {
        // Each item carries its own fields; a top-level one would apply to no item.
        const topLevel = BATCH_ITEM_FIELDS.filter((field) => params[field] !== undefined);
        if (topLevel.length) {
          return errorResult(
            state,
            `create with tasks[] takes ${topLevel.join(", ")} on each item, not at the top level`,
          );
        }
        if (batch.length === 0) {
          return errorResult(state, "tasks[] must be non-empty");
        }
        const items: Array<{ spec: TaskMutationParams; subject: string }> = [];
        for (let i = 0; i < batch.length; i++) {
          const spec = asCreateItem(batch[i]);
          const subject = spec?.subject;
          if (!spec || !subject?.trim()) {
            return errorResult(state, `tasks[${i}]: subject required for create`);
          }
          items.push({ spec, subject });
        }
        const siblingIds = new Set(items.map((_, i) => state.nextId + i));
        const parentOf = (item: { spec: TaskMutationParams }) => item.spec.parentId ?? params.parentId ?? undefined;
        for (const item of items) {
          const error =
            validateCreateBlockedBy(state, item.spec.blockedBy, siblingIds) ??
            validateParent(state, parentOf(item), siblingIds);
          if (error) return errorResult(state, error);
        }
        const created = items.map((item, i) =>
          buildCreatedTask(state.nextId + i, item.spec, item.subject, parentOf(item)),
        );
        return {
          state: { tasks: [...state.tasks, ...created], nextId: state.nextId + created.length },
          op: { kind: "create", taskIds: created.map((t) => t.id) },
        };
      }

      if (!params.subject?.trim()) {
        return errorResult(state, "subject required for create");
      }
      const parentId = params.parentId ?? undefined;
      const error =
        validateCreateBlockedBy(state, params.blockedBy, new Set()) ?? validateParent(state, parentId, new Set());
      if (error) return errorResult(state, error);
      const newTask = buildCreatedTask(state.nextId, params, params.subject, parentId);
      return {
        state: { tasks: [...state.tasks, newTask], nextId: state.nextId + 1 },
        op: { kind: "create", taskIds: [newTask.id] },
      };
    }

    case "update": {
      if (params.id === undefined) return errorResult(state, "id required for update");
      const idx = state.tasks.findIndex((t) => t.id === params.id);
      if (idx === -1) return errorResult(state, `#${params.id} not found`);
      const current = state.tasks[idx];

      const hasMutation =
        params.subject !== undefined ||
        params.description !== undefined ||
        params.activeForm !== undefined ||
        params.status !== undefined ||
        params.owner !== undefined ||
        params.parentId !== undefined ||
        params.metadata !== undefined ||
        (params.addBlockedBy && params.addBlockedBy.length > 0) ||
        (params.removeBlockedBy && params.removeBlockedBy.length > 0);
      if (!hasMutation)
        return errorResult(
          state,
          "update requires at least one mutable field: subject, description, activeForm, status, parentId, owner, metadata, addBlockedBy, or removeBlockedBy",
        );

      let newStatus = current.status;
      if (params.status !== undefined) {
        if (!isTransitionValid(current.status, params.status)) {
          return errorResult(state, `illegal transition ${current.status} → ${params.status}`);
        }
        newStatus = params.status;
      }
      const unfinished = liveDescendants(state.tasks, current.id).filter((t) => t.status !== "completed");
      if (newStatus === "completed" && current.status !== "completed" && unfinished.length) {
        return errorResult(
          state,
          `cannot complete #${current.id}: subtasks ${unfinished.map((t) => `#${t.id}`).join(", ")} are unfinished`,
        );
      }

      let newParentId = current.parentId;
      if (params.parentId !== undefined) {
        newParentId = params.parentId ?? undefined;
        if (newParentId === current.id) return errorResult(state, `cannot nest #${current.id} under itself`);
        if (newParentId !== undefined && liveDescendants(state.tasks, current.id).some((t) => t.id === newParentId)) {
          return errorResult(state, `parentId: #${newParentId} is a subtask of #${current.id}`);
        }
        const subtreeDone = newStatus === "completed" && unfinished.length === 0;
        const parentError = validateParent(state, newParentId, new Set(), subtreeDone);
        if (parentError) return errorResult(state, parentError);
      }

      let newBlockedBy = current.blockedBy ? [...current.blockedBy] : [];
      if (params.removeBlockedBy?.length) {
        const toRemove = new Set(params.removeBlockedBy);
        newBlockedBy = newBlockedBy.filter((dep) => !toRemove.has(dep));
      }
      if (params.addBlockedBy?.length) {
        for (const dep of params.addBlockedBy) {
          if (dep === current.id) return errorResult(state, `cannot block #${current.id} on itself`);
          const depTask = state.tasks.find((t) => t.id === dep);
          if (!depTask) return errorResult(state, `addBlockedBy: #${dep} not found`);
          if (depTask.status === "deleted") return errorResult(state, `addBlockedBy: #${dep} is deleted`);
          if (!newBlockedBy.includes(dep)) newBlockedBy.push(dep);
        }
        if (detectCycle(state.tasks, current.id, newBlockedBy)) {
          return errorResult(state, "addBlockedBy would create a cycle in the blockedBy graph");
        }
      }

      let newMetadata = current.metadata;
      if (params.metadata !== undefined) {
        const merged: Record<string, unknown> = { ...current.metadata };
        for (const [k, v] of Object.entries(params.metadata)) {
          if (v === null) delete merged[k];
          else merged[k] = v;
        }
        newMetadata = Object.keys(merged).length ? merged : undefined;
      }

      const updated: Task = { ...current, status: newStatus };
      if (params.subject !== undefined) updated.subject = params.subject;
      if (params.description !== undefined) updated.description = params.description;
      if (params.activeForm !== undefined) updated.activeForm = params.activeForm;
      if (params.owner !== undefined) updated.owner = params.owner;
      if (newParentId === undefined) delete updated.parentId;
      else updated.parentId = newParentId;
      if (newBlockedBy.length) updated.blockedBy = newBlockedBy;
      else delete updated.blockedBy;
      if (newMetadata === undefined) delete updated.metadata;
      else updated.metadata = newMetadata;

      const newTasks = [...state.tasks];
      newTasks[idx] = updated;
      if (newStatus === "deleted" && current.status !== "deleted") promoteChildren(newTasks, updated);
      return {
        state: { tasks: newTasks, nextId: state.nextId },
        op: {
          kind: "update",
          id: updated.id,
          fromStatus: current.status,
          toStatus: newStatus,
          changed: taskChanged(current, updated),
        },
      };
    }

    case "list": {
      return {
        state,
        op: {
          kind: "list",
          includeDeleted: params.includeDeleted === true,
          ...(params.status !== undefined ? { statusFilter: params.status } : {}),
        },
      };
    }

    case "get": {
      if (params.id === undefined) return errorResult(state, "id required for get");
      const task = state.tasks.find((t) => t.id === params.id);
      if (!task) return errorResult(state, `#${params.id} not found`);
      return { state, op: { kind: "get", task } };
    }

    case "delete": {
      if (params.id === undefined) return errorResult(state, "id required for delete");
      const idx = state.tasks.findIndex((t) => t.id === params.id);
      if (idx === -1) return errorResult(state, `#${params.id} not found`);
      const current = state.tasks[idx];
      if (current.status === "deleted") return errorResult(state, `#${current.id} is already deleted`);
      const updated: Task = { ...current, status: "deleted" };
      const newTasks = [...state.tasks];
      newTasks[idx] = updated;
      const promoted = promoteChildren(newTasks, updated);
      return {
        state: { tasks: newTasks, nextId: state.nextId },
        op: { kind: "delete", id: updated.id, subject: updated.subject, promoted },
      };
    }

    case "clear": {
      const count = state.tasks.length;
      return {
        state: { tasks: [], nextId: 1 },
        op: { kind: "clear", count },
      };
    }
  }
}
