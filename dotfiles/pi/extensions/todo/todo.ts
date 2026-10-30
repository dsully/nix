import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { applyTaskMutation, changesState } from "./state/state-reducer.js";
import { commitState, getRenderState, getState, sid } from "./state/store.js";
import { prepareTodoArguments } from "./tool/normalize-params.js";
import { buildToolResult } from "./tool/response-envelope.js";
import {
  COMMAND_NAME,
  ERR_REQUIRES_INTERACTIVE,
  MSG_NO_TODOS,
  STATE_ENTRY_TYPE,
  type TaskMutationParams,
  TodoParamsSchema,
  TOOL_LABEL,
  TOOL_NAME,
} from "./tool/types.js";
import { TodoBrowser } from "./view/browser.js";
import { renderTodoCall, renderTodoResult } from "./view/format.js";

export { TOOL_NAME } from "./tool/types.js";

const TOOL_DESCRIPTION =
  "Task tracker. action is required: create|update|list|get|delete|clear; create needs subject; update/get/delete need id.";
const PROMPT_GUIDELINES = [
  "todo: Use for multi-step tasks; set each step in_progress before starting it and completed as soon as it finishes, one at a time, never batched at the end. update needs changed fields; list accepts status/includeDeleted; clear removes all; create supports blockedBy or a tasks[] batch; update supports addBlockedBy/removeBlockedBy.",
  "todo: parentId nests a subtask (create, each tasks[] item, or top-level for the whole batch); update moves it, null to root. A parent completes only after all its subtasks.",
];

export function registerTodoTool(pi: ExtensionAPI): void {
  pi.registerTool({
    name: TOOL_NAME,
    label: TOOL_LABEL,
    description: TOOL_DESCRIPTION,
    promptSnippet: "",
    promptGuidelines: PROMPT_GUIDELINES,
    parameters: TodoParamsSchema,
    prepareArguments: prepareTodoArguments,

    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      const result = applyTaskMutation(getState(sid(ctx)), params.action, params as TaskMutationParams);
      commitState(sid(ctx), result.state);
      const toolResult = buildToolResult(params.action, params as TaskMutationParams, result.state, result.op);
      // A call made through another tool (codemode's ctx.executeTool) never lands as a toolResult, so persist explicitly.
      if (changesState(result.op)) pi.appendEntry(STATE_ENTRY_TYPE, toolResult.details);
      return toolResult;
    },

    // ToolRenderContext has no session identity, so a child session's call falls back to `#id` here.
    renderCall(args, theme, _context) {
      return renderTodoCall(args as never, theme, getRenderState());
    },

    renderResult(result, _opts, theme, context) {
      return renderTodoResult(result, theme, context?.isError);
    },
  });
}

export function registerTodosCommand(pi: ExtensionAPI): void {
  pi.registerCommand(COMMAND_NAME, {
    description: "Browse the todo tree on the current branch",
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) {
        ctx.ui.notify(ERR_REQUIRES_INTERACTIVE, "error");
        return;
      }
      const id = sid(ctx);
      if (!getState(id).tasks.some((t) => t.status !== "deleted")) {
        ctx.ui.notify(MSG_NO_TODOS, "info");
        return;
      }
      await ctx.ui.custom<void>(
        (tui, theme, _keybindings, done) => new TodoBrowser(tui, theme, () => getState(id), done),
        {
          overlay: true,
          overlayOptions: { width: "80%", maxHeight: "70%", anchor: "center" },
        },
      );
    },
  });
}
