import type { Task } from "../tool/types.js";

/**
 * Detect whether merging `newBlockedBy` into `taskId`'s `blockedBy` set would
 * introduce a cycle in the dependency graph.
 *
 * Pure of any module state; takes the existing `taskList` and the proposed
 * additions explicitly so the reducer can ask "would this update cycle?"
 * without mutating state first.
 */
export function detectCycle(taskList: readonly Task[], taskId: number, newBlockedBy: readonly number[]): boolean {
  const edges = new Map<number, number[]>();
  for (const t of taskList) {
    if (t.id === taskId) {
      const merged = new Set([...(t.blockedBy ?? []), ...newBlockedBy]);
      edges.set(t.id, [...merged]);
    } else {
      edges.set(t.id, t.blockedBy ? [...t.blockedBy] : []);
    }
  }

  const visiting = new Set<number>();
  const visited = new Set<number>();
  const hasCycleFrom = (node: number): boolean => {
    if (visiting.has(node)) return true;
    if (visited.has(node)) return false;
    visiting.add(node);
    for (const nb of edges.get(node) ?? []) {
      if (hasCycleFrom(nb)) return true;
    }
    visiting.delete(node);
    visited.add(node);
    return false;
  };

  for (const node of edges.keys()) {
    if (hasCycleFrom(node)) return true;
  }
  return false;
}

/**
 * Build the inverse adjacency map: for each task `T`, which other tasks list
 * `T` in their `blockedBy`. Consumed by `selectShowTaskIds` (overlay gating)
 * and the `get` action's "blocks: #x, #y" suffix line.
 */
export function deriveBlocks(taskList: readonly Task[]): Map<number, number[]> {
  const blocks = new Map<number, number[]>();
  for (const t of taskList) {
    for (const dep of t.blockedBy ?? []) {
      const arr = blocks.get(dep) ?? [];
      arr.push(t.id);
      blocks.set(dep, arr);
    }
  }
  return blocks;
}

/** Live (non-deleted) direct children of `parentId`, in list order. */
export function liveChildren(taskList: readonly Task[], parentId: number): Task[] {
  return taskList.filter((t) => t.parentId === parentId && t.status !== "deleted");
}

/** Every live task below `id`, depth-first. */
export function liveDescendants(taskList: readonly Task[], id: number): Task[] {
  const out: Task[] = [];
  const walk = (parent: number): void => {
    for (const child of liveChildren(taskList, parent)) {
      out.push(child);
      walk(child.id);
    }
  };
  walk(id);
  return out;
}

export interface TreeRow {
  task: Task;
  depth: number;
}

/**
 * Depth-first rows of `taskList`, children after their parent in list order. A task whose parent is
 * not in `taskList` is a root, so a filtered list still renders every task exactly once.
 */
export function treeRows(taskList: readonly Task[]): TreeRow[] {
  const ids = new Set(taskList.map((t) => t.id));
  const children = new Map<number | undefined, Task[]>();
  for (const t of taskList) {
    const key = t.parentId !== undefined && ids.has(t.parentId) ? t.parentId : undefined;
    const list = children.get(key) ?? [];
    list.push(t);
    children.set(key, list);
  }
  const rows: TreeRow[] = [];
  const walk = (parent: number | undefined, depth: number): void => {
    for (const task of children.get(parent) ?? []) {
      rows.push({ task, depth });
      walk(task.id, depth + 1);
    }
  };
  walk(undefined, 0);
  return rows;
}

export interface BrowserRow extends TreeRow {
  hasChildren: boolean;
}

/** Live tasks in tree order, skipping everything below a folded task. */
export function browserRows(taskList: readonly Task[], folded: ReadonlySet<number>): BrowserRow[] {
  const live = taskList.filter((t) => t.status !== "deleted");
  const parents = new Set(live.map((t) => t.parentId));
  const rows: BrowserRow[] = [];
  let foldDepth: number | undefined;
  for (const row of treeRows(live)) {
    if (foldDepth !== undefined && row.depth > foldDepth) continue;
    foldDepth = folded.has(row.task.id) ? row.depth : undefined;
    rows.push({ ...row, hasChildren: parents.has(row.task.id) });
  }
  return rows;
}
