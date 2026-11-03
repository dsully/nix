import type { Task } from "../tool/types.js";

/** Keep it minimal: derived values belong in `selectors.ts`, not here. */
export interface TaskState {
  tasks: Task[];
  nextId: number;
}

export const EMPTY_STATE: TaskState = { tasks: [], nextId: 1 };
