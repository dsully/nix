import { StringEnum } from "@earendil-works/pi-ai";
import { type Static, Type } from "typebox";

// "todo" and "rpiv-todo-state" are the replay keys for existing session branches; do not rename.
export const TOOL_NAME = "todo";
export const TOOL_LABEL = "Todo";
export const COMMAND_NAME = "todos";
export const STATE_ENTRY_TYPE = "rpiv-todo-state";

export const ERR_REQUIRES_INTERACTIVE = "/todos requires interactive mode";
export const MSG_NO_TODOS = "No todos yet. Ask the agent to add some!";

export type TaskStatus = "pending" | "in_progress" | "completed" | "deleted";

export type TaskAction = "create" | "update" | "list" | "get" | "delete" | "clear";

export interface Task {
  id: number;
  subject: string;
  description?: string;
  activeForm?: string;
  status: TaskStatus;
  parentId?: number;
  blockedBy?: number[];
  owner?: string;
  metadata?: Record<string, unknown>;
}

/** Replay snapshot returned under `details` by every call; field names are pinned by replay compatibility. */
export interface TaskDetails {
  action: TaskAction;
  params: Record<string, unknown>;
  tasks: Task[];
  nextId: number;
  error?: string;
}

/** One item of a batch `create` `tasks[]` payload. */
export interface CreateTaskInput {
  subject: string;
  description?: string;
  activeForm?: string;
  parentId?: number;
  blockedBy?: number[];
  owner?: string;
  metadata?: Record<string, unknown>;
}

export interface TaskMutationParams {
  [key: string]: unknown;
  subject?: string;
  description?: string;
  activeForm?: string;
  status?: TaskStatus;
  /** `null` on update moves the task to the root. */
  parentId?: number | null;
  blockedBy?: number[];
  addBlockedBy?: number[];
  removeBlockedBy?: number[];
  owner?: string;
  metadata?: Record<string, unknown>;
  id?: number;
  includeDeleted?: boolean;
  tasks?: CreateTaskInput[];
}

// No per-field descriptions: the tool description and guideline carry the contract at a fraction of the tokens.
const CreateTaskInputSchema = Type.Object({
  subject: Type.String(),
  description: Type.Optional(Type.String()),
  activeForm: Type.Optional(Type.String()),
  parentId: Type.Optional(Type.Number()),
  blockedBy: Type.Optional(Type.Array(Type.Number())),
  owner: Type.Optional(Type.String()),
  metadata: Type.Optional(Type.Record(Type.String(), Type.Unknown())),
});

export const TodoParamsSchema = Type.Object({
  action: StringEnum(["create", "update", "list", "get", "delete", "clear"] as const),
  subject: Type.Optional(Type.String()),
  description: Type.Optional(Type.String()),
  activeForm: Type.Optional(Type.String()),
  status: Type.Optional(StringEnum(["pending", "in_progress", "completed", "deleted"] as const)),
  parentId: Type.Optional(Type.Union([Type.Number(), Type.Null()])),
  blockedBy: Type.Optional(Type.Array(Type.Number())),
  addBlockedBy: Type.Optional(Type.Array(Type.Number())),
  removeBlockedBy: Type.Optional(Type.Array(Type.Number())),
  owner: Type.Optional(Type.String()),
  metadata: Type.Optional(Type.Record(Type.String(), Type.Unknown())),
  id: Type.Optional(Type.Number()),
  includeDeleted: Type.Optional(Type.Boolean()),
  tasks: Type.Optional(Type.Array(CreateTaskInputSchema)),
});

export type TodoParams = Static<typeof TodoParamsSchema>;
