import { EMPTY_STATE, type TaskState } from "./state.js";

/** Live task state per session id, so a child session can never read or clobber another session's tasks. */
const sessions = new Map<string, TaskState>();

/** The session whose tasks the ctx-less readers (the overlay, the tool's renderCall) show. Claimed by the first UI session. */
let activeRenderSession = "";

export function sid(ctx: { sessionManager: { getSessionId(): string } }): string {
  return ctx.sessionManager.getSessionId() ?? "";
}

/** A missing slot reads as a fresh copy, never as `EMPTY_STATE` itself, so callers cannot alias it. */
function slotFor(sessionId: string): TaskState {
  return sessions.get(sessionId) ?? { tasks: [...EMPTY_STATE.tasks], nextId: EMPTY_STATE.nextId };
}

export function getState(sessionId: string): TaskState {
  return slotFor(sessionId);
}

/** The only writer of task state: replayed snapshots and reducer results both land here. */
export function setState(sessionId: string, next: TaskState): void {
  sessions.set(sessionId, next);
}

export function evictSession(sessionId: string): void {
  sessions.delete(sessionId);
}

export function getRenderState(): TaskState {
  return slotFor(activeRenderSession);
}

export function setActiveRenderSession(sessionId: string): void {
  activeRenderSession = sessionId;
}

export function getActiveRenderSession(): string {
  return activeRenderSession;
}

/** Clearing lets the next UI session_start reclaim the foreground. */
export function clearActiveRenderSession(): void {
  activeRenderSession = "";
}
