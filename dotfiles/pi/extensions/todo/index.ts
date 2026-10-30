/**
 * `todo` tool, `/todos` tree browser, and the above-editor todo widget.
 * Vendored from @juicesharp/rpiv-todo 2.15.0 (MIT) with @ssk_dev/rpiv-todo-lean's prompt text;
 * the "todo" tool name and "rpiv-todo-state" entry type are kept so existing sessions replay.
 */

import type { ExtensionAPI, ExtensionUIContext } from "@earendil-works/pi-coding-agent";
import { replayFromBranch } from "./state/replay.js";
import {
  clearActiveRenderSession,
  evictSession,
  getActiveRenderSession,
  getRenderState,
  replaceState,
  setActiveRenderSession,
  sid,
} from "./state/store.js";
import { COLLAPSE_KEY, TodoOverlay } from "./todo-overlay.js";
import { registerTodosCommand, registerTodoTool, TOOL_NAME } from "./todo.js";

// pi's ExtensionRunner throws this from an invalidated ctx proxy after session replacement or reload.
function isStaleCtxError(e: unknown): boolean {
  return /stale after session replacement/.test(String(e));
}

export default function (pi: ExtensionAPI) {
  let todoOverlay: TodoOverlay | undefined;
  let uiCtx: ExtensionUIContext | undefined;

  function updateTodoOverlay(resetCompletedDisplayState = false): void {
    const hasVisibleTasks = getRenderState().tasks.some((task) => task.status !== "deleted");
    if (!uiCtx || (!todoOverlay && !hasVisibleTasks)) return;
    todoOverlay ??= new TodoOverlay();
    todoOverlay.setUICtx(uiCtx);
    if (resetCompletedDisplayState) todoOverlay.resetCompletedDisplayState();
    todoOverlay.update();
  }

  registerTodoTool(pi);
  registerTodosCommand(pi);

  pi.registerShortcut(COLLAPSE_KEY, {
    description: "Collapse or expand the todo overlay",
    handler: (ctx) => {
      if (!ctx.hasUI || !todoOverlay?.isRegistered()) return;
      todoOverlay.toggleCollapse();
    },
  });

  // Each session replays into its own slot; only the foreground session drives the shared widget.
  const replayAndRefresh = (ctx: Parameters<typeof sid>[0] & Parameters<typeof replayFromBranch>[0]): void => {
    let isForeground = false;
    try {
      const id = sid(ctx);
      replaceState(id, replayFromBranch(ctx));
      isForeground = id === getActiveRenderSession();
    } catch (e) {
      if (!isStaleCtxError(e)) throw e;
    }
    if (isForeground) updateTodoOverlay(true);
  };

  pi.on("session_start", async (_event, ctx) => {
    let id: string;
    try {
      id = sid(ctx);
      replaceState(id, replayFromBranch(ctx));
    } catch (e) {
      if (!isStaleCtxError(e)) throw e;
      return;
    }
    if (!ctx.hasUI) return;
    // The first UI-bearing session claims the foreground; children keep their own slot without rebinding the widget.
    if (getActiveRenderSession() === "") setActiveRenderSession(id);
    if (id !== getActiveRenderSession()) return;
    uiCtx = ctx.ui;
    updateTodoOverlay(true);
  });

  pi.on("session_compact", async (_event, ctx) => replayAndRefresh(ctx));
  pi.on("session_tree", async (_event, ctx) => replayAndRefresh(ctx));

  pi.on("session_shutdown", async (_event, ctx) => {
    let s: string;
    try {
      s = sid(ctx);
    } catch (e) {
      if (!isStaleCtxError(e)) throw e;
      s = "";
    }
    evictSession(s);
    if (s !== "" && s !== getActiveRenderSession()) return;
    uiCtx = undefined;
    // dispose() calls setWidget on a possibly stale ui proxy, which can throw; the pointer must still clear.
    try {
      todoOverlay?.dispose();
    } finally {
      todoOverlay = undefined;
      clearActiveRenderSession();
    }
  });

  // Reads live state at render time: the branch is stale here because message_end runs after tool_execution_end.
  pi.on("tool_execution_end", async (event) => {
    if (event.toolName !== TOOL_NAME || event.isError) return;
    updateTodoOverlay();
  });

  pi.on("agent_start", async () => {
    todoOverlay?.hideCompletedTasksFromPreviousTurn();
  });
}
