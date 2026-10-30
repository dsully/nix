import type { TodoParams } from "./types.js";

const MUTABLE_FIELDS = [
  "subject",
  "description",
  "activeForm",
  "status",
  "parentId",
  "owner",
  "metadata",
  "addBlockedBy",
  "removeBlockedBy",
];

/**
 * Pi's `prepareArguments` hook, before schema validation: infer a missing `action` from the fields sent, and
 * decode a `tasks[]` (or its items) that some tool-call parsers emit as JSON strings.
 */
export function prepareTodoArguments(args: unknown): TodoParams {
  if (!isRecord(args)) return args as TodoParams;
  let input = args;
  if (input.action === undefined) {
    const action =
      input.id !== undefined && MUTABLE_FIELDS.some((field) => field in input)
        ? "update"
        : typeof input.subject === "string" || input.tasks !== undefined
          ? "create"
          : input.id !== undefined && Object.keys(input).every((key) => key === "id" || key === "includeDeleted")
            ? "get"
            : undefined;
    if (action) input = { ...input, action };
  }
  if (input.tasks === undefined) return input as TodoParams;
  const tasks = decodeArray(input.tasks);
  if (!Array.isArray(tasks)) return input as TodoParams;
  const decoded = tasks.map(decodeObject);
  if (tasks === input.tasks && decoded.every((item, i) => item === tasks[i])) return input as TodoParams;
  return { ...input, tasks: decoded } as unknown as TodoParams;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function decodeArray(value: unknown): unknown {
  const parsed = typeof value === "string" ? parseJson(value) : value;
  return Array.isArray(parsed) ? parsed : value;
}

function decodeObject(value: unknown): unknown {
  const parsed = typeof value === "string" ? parseJson(value) : value;
  return isRecord(parsed) ? parsed : value;
}

function parseJson(text: string): unknown {
  try {
    return JSON.parse(text);
  } catch {
    return undefined;
  }
}
