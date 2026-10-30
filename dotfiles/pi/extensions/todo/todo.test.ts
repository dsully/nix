import { expect, test } from "bun:test";
import { replayFromBranch } from "./state/replay.js";
import { EMPTY_STATE, type TaskState } from "./state/state.js";
import { applyTaskMutation } from "./state/state-reducer.js";
import { browserRows, treeRows } from "./state/task-graph.js";
import { prepareTodoArguments } from "./tool/normalize-params.js";
import type { TaskAction, TaskMutationParams } from "./tool/types.js";

function run(steps: Array<[TaskAction, TaskMutationParams]>): TaskState {
  let state: TaskState = { ...EMPTY_STATE, tasks: [] };
  for (const [action, params] of steps) {
    const result = applyTaskMutation(state, action, params);
    if (result.op.kind === "error") throw new Error(result.op.message);
    state = result.state;
  }
  return state;
}

function error(state: TaskState, action: TaskAction, params: TaskMutationParams): string | undefined {
  const { op } = applyTaskMutation(state, action, params);
  return op.kind === "error" ? op.message : undefined;
}

const byId = (state: TaskState, id: number) => state.tasks.find((t) => t.id === id);

// #1 root, #2 and #3 under #1, #4 under #2
const nested = () =>
  run([
    ["create", { subject: "root" }],
    ["create", { parentId: 1, tasks: [{ subject: "a" }, { subject: "b" }] }],
    ["create", { subject: "a.a", parentId: 2 }],
  ]);

test("batch items take the top-level parentId unless they set their own", () => {
  const state = run([
    ["create", { subject: "p" }],
    ["create", { subject: "q" }],
    ["create", { parentId: 1, tasks: [{ subject: "x" }, { subject: "y", parentId: 2 }] }],
  ]);
  expect(byId(state, 3)?.parentId).toBe(1);
  expect(byId(state, 4)?.parentId).toBe(2);
});

test("a parent must exist, be live, be unfinished, and not be a batch sibling", () => {
  const state = run([
    ["create", { subject: "done" }],
    ["update", { id: 1, status: "completed" }],
    ["create", { subject: "gone" }],
    ["delete", { id: 2 }],
  ]);
  expect(error(state, "create", { subject: "x", parentId: 9 })).toBeDefined();
  expect(error(state, "create", { subject: "x", parentId: 1 })).toBeDefined();
  expect(error(state, "create", { subject: "x", parentId: 2 })).toBeDefined();
  expect(error(state, "create", { tasks: [{ subject: "x" }, { subject: "y", parentId: state.nextId }] })).toBeDefined();
});

test("a parent completes only after every live descendant", () => {
  const state = nested();
  expect(error(state, "update", { id: 1, status: "completed" })).toBeDefined();
  expect(error(state, "update", { id: 2, status: "completed" })).toBeDefined();
  const done = run([
    ["create", { subject: "root" }],
    ["create", { subject: "child", parentId: 1 }],
    ["update", { id: 2, status: "completed" }],
    ["update", { id: 1, status: "completed" }],
  ]);
  expect(byId(done, 1)?.status).toBe("completed");
});

test("reparenting rejects self and descendants, and null moves to the root", () => {
  const state = nested();
  expect(error(state, "update", { id: 2, parentId: 2 })).toBeDefined();
  expect(error(state, "update", { id: 1, parentId: 4 })).toBeDefined();
  const moved = applyTaskMutation(state, "update", { id: 4, parentId: null }).state;
  expect(byId(moved, 4)?.parentId).toBeUndefined();
});

test("deleting a parent moves its live children up one level", () => {
  for (const params of [{ id: 2 }, { id: 2, status: "deleted" as const }]) {
    const state = applyTaskMutation(nested(), params.status ? "update" : "delete", params).state;
    expect(byId(state, 4)?.parentId).toBe(1);
    const deleted = new Set(state.tasks.filter((t) => t.status === "deleted").map((t) => t.id));
    expect(state.tasks.some((t) => t.status !== "deleted" && deleted.has(t.parentId ?? 0))).toBe(false);
  }
});

test("tree rows list each task once, children after their parent", () => {
  const rows = treeRows(nested().tasks);
  expect(rows.map((r) => r.task.id).sort()).toEqual([1, 2, 3, 4]);
  for (const row of rows) {
    if (row.task.parentId === undefined) continue;
    const parentIndex = rows.findIndex((r) => r.task.id === row.task.parentId);
    expect(parentIndex).toBeLessThan(rows.indexOf(row));
    expect(row.depth).toBe(rows[parentIndex].depth + 1);
  }
});

test("folding hides a task's descendants but not its siblings", () => {
  const ids = browserRows(nested().tasks, new Set([2])).map((r) => r.task.id);
  expect(ids).toContain(3);
  expect(ids).not.toContain(4);
  expect(browserRows(nested().tasks, new Set([1])).map((r) => r.task.id)).toEqual([1]);
});

test("replay keeps parentId from persisted snapshots", () => {
  const tasks = nested().tasks;
  const branch = [
    { type: "custom", customType: "rpiv-todo-state", data: { action: "create", params: {}, tasks, nextId: 5 } },
  ];
  expect(replayFromBranch({ sessionManager: { getBranch: () => branch } }).tasks).toEqual(tasks);
});

test("a missing action is inferred, including for parentId-only updates", () => {
  expect(prepareTodoArguments({ id: 3, parentId: null }).action).toBe("update");
  expect(prepareTodoArguments({ subject: "x" }).action).toBe("create");
  expect(prepareTodoArguments({ id: 3 }).action).toBe("get");
});
