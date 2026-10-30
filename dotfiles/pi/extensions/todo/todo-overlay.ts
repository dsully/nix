/**
 * Above-editor widget: register once, refresh with requestRender(), at most MAX_WIDGET_LINES content rows plus a
 * trailing spacer, hidden when empty. Reads live state via getRenderState() at render time.
 */

import type { ExtensionUIContext, Theme } from "@earendil-works/pi-coding-agent";
import { type KeyId, type TUI, truncateToWidth } from "@earendil-works/pi-tui";
import { selectHasActive, selectOverlayLayout, selectShowTaskIds, selectTodoCounts } from "./state/selectors.js";
import { getRenderState } from "./state/store.js";
import { liveChildren, treeRows } from "./state/task-graph.js";
import { formatOverlayTaskLine, formatStatusLabel } from "./view/format.js";

const WIDGET_KEY = "rpiv-todos";
const MAX_WIDGET_LINES = 12;
export const COLLAPSE_KEY: KeyId = "ctrl+shift+t";

export class TodoOverlay {
  private uiCtx: ExtensionUIContext | undefined;
  private widgetRegistered = false;
  private tui: TUI | undefined;
  private completedTaskIdsPendingHide = new Set<number>();
  private hiddenCompletedTaskIds = new Set<number>();
  private lastNextId: number | undefined;
  private collapsed = false;

  setUICtx(ctx: ExtensionUIContext): void {
    // Identity-compare so repeat session_start handlers are idempotent;
    // on identity change (/reload) invalidate so update() re-registers.
    if (ctx !== this.uiCtx) {
      this.uiCtx = ctx;
      this.widgetRegistered = false;
      this.tui = undefined;
    }
  }

  update(): void {
    if (!this.uiCtx) return;
    const snapshot = this.getSnapshot();
    const visible = this.selectOverlayTasks(snapshot);

    if (visible.length === 0) {
      if (this.widgetRegistered) {
        this.uiCtx.setWidget(WIDGET_KEY, undefined);
        this.widgetRegistered = false;
        this.tui = undefined;
      }
      return;
    }

    if (!this.widgetRegistered) {
      this.uiCtx.setWidget(
        WIDGET_KEY,
        (tui, factoryTheme) => {
          this.tui = tui;
          return {
            render: (width: number) => this.renderWidget(this.uiCtx?.theme ?? factoryTheme, width),
            invalidate: () => {
              // No rendered strings are cached. Pi invalidates on theme changes;
              // the next render reads uiCtx.theme.
            },
          };
        },
        { placement: "aboveEditor" },
      );
      this.widgetRegistered = true;
    } else {
      this.tui?.requestRender();
    }
  }

  resetCompletedDisplayState(): void {
    this.completedTaskIdsPendingHide.clear();
    this.hiddenCompletedTaskIds.clear();
    this.lastNextId = undefined;
  }

  hideCompletedTasksFromPreviousTurn(): void {
    if (this.completedTaskIdsPendingHide.size === 0) return;
    for (const taskId of this.completedTaskIdsPendingHide) {
      this.hiddenCompletedTaskIds.add(taskId);
    }
    this.completedTaskIdsPendingHide.clear();
    this.tui?.requestRender();
  }

  toggleCollapse(): void {
    this.collapsed = !this.collapsed;
    // Forced full redraw on the collapsed↔expanded height step, mirroring the
    // lane-dock's requestRender(shapeChanged); distinct from the non-forced
    // requestRender() refresh paths in update()/hideCompletedTasksFromPreviousTurn().
    this.tui?.requestRender(true);
  }

  isRegistered(): boolean {
    return this.widgetRegistered;
  }

  private getSnapshot() {
    const state = getRenderState();
    if (this.lastNextId !== undefined && state.nextId < this.lastNextId) {
      this.resetCompletedDisplayState();
    }
    this.lastNextId = state.nextId;
    const completedTaskIds = new Set(state.tasks.filter((task) => task.status === "completed").map((task) => task.id));
    for (const taskId of this.completedTaskIdsPendingHide) {
      if (!completedTaskIds.has(taskId)) this.completedTaskIdsPendingHide.delete(taskId);
    }
    for (const taskId of this.hiddenCompletedTaskIds) {
      if (!completedTaskIds.has(taskId)) this.hiddenCompletedTaskIds.delete(taskId);
    }
    return { tasks: [...state.tasks], nextId: state.nextId };
  }

  private selectOverlayTasks(snapshot: ReturnType<TodoOverlay["getSnapshot"]>) {
    const shown = snapshot.tasks.filter((task) => task.status !== "deleted" && !this.shouldHideCompletedTask(task));
    return treeRows(shown).map((row) => row.task);
  }

  private shouldHideCompletedTask(task: ReturnType<TodoOverlay["getSnapshot"]>["tasks"][number]): boolean {
    return task.status === "completed" && this.hiddenCompletedTaskIds.has(task.id);
  }

  private renderWidget(theme: Theme, width: number): string[] {
    const snapshot = this.getSnapshot();
    const overlayTasks = this.selectOverlayTasks(snapshot);
    if (overlayTasks.length === 0) return [];

    const overlayState = { tasks: overlayTasks, nextId: snapshot.nextId };
    const truncate = (line: string): string => truncateToWidth(line, width, "…");
    const counts = selectTodoCounts(overlayState);
    const hasActive = selectHasActive(overlayState);
    const showIds = selectShowTaskIds(overlayState);

    const headingColor = hasActive ? "accent" : "dim";
    const headingIcon = hasActive ? "●" : "○";
    const headingText = `Todos (${counts.completed}/${counts.total})`;
    const heading = truncate(`${theme.fg(headingColor, headingIcon)} ${theme.fg(headingColor, headingText)}`);

    if (this.collapsed) {
      const hint = `${COLLAPSE_KEY} to expand`;
      return this.withTrailingSpacer([heading, truncate(`${theme.fg("dim", "└─")} ${theme.fg("dim", hint)}`)]);
    }

    const lines: string[] = [heading];
    // Pi's tool-output expansion toggle also expands this widget; the spacer row sits outside the budget.
    const bodyBudget = this.uiCtx?.getToolsExpanded?.() === true ? overlayTasks.length : MAX_WIDGET_LINES - 1;
    const layout = selectOverlayLayout(overlayState, bodyBudget);
    const depth = new Map(treeRows(overlayTasks).map((row) => [row.task.id, row.depth]));
    for (const task of layout.visible) {
      const children = liveChildren(snapshot.tasks, task.id);
      const progress = { done: children.filter((c) => c.status === "completed").length, total: children.length };
      const indent = "  ".repeat(depth.get(task.id) ?? 0);
      lines.push(
        truncate(`${theme.fg("dim", "├─")} ${indent}${formatOverlayTaskLine(task, theme, showIds, progress)}`),
      );
    }

    const newlyDisplayedCompletedTaskIds = overlayTasks
      .filter(
        (task) =>
          task.status === "completed" &&
          !this.completedTaskIdsPendingHide.has(task.id) &&
          !this.hiddenCompletedTaskIds.has(task.id),
      )
      .map((task) => task.id);
    for (const taskId of newlyDisplayedCompletedTaskIds) {
      this.completedTaskIdsPendingHide.add(taskId);
    }

    if (layout.hiddenCompleted === 0 && layout.truncatedTail === 0) {
      const last = lines.length - 1;
      lines[last] = lines[last].replace("├─", "└─");
      return this.withTrailingSpacer(lines);
    }

    const totalHidden = layout.hiddenCompleted + layout.truncatedTail;
    const overflowParts: string[] = [];
    if (layout.hiddenCompleted > 0) overflowParts.push(`${layout.hiddenCompleted} ${formatStatusLabel("completed")}`);
    if (layout.truncatedTail > 0) overflowParts.push(`${layout.truncatedTail} ${formatStatusLabel("pending")}`);
    const more = "more";
    const summary =
      overflowParts.length > 0 ? `+${totalHidden} ${more} (${overflowParts.join(", ")})` : `+${totalHidden} ${more}`;
    lines.push(truncate(`${theme.fg("dim", "└─")} ${theme.fg("dim", summary)}`));
    return this.withTrailingSpacer(lines);
  }

  /**
   * Append a trailing blank line so the overlay isn't flush against the
   * editor box. Pi's host adds a leading spacer above the widget but none
   * below, which leaves the last "└─" row (or the "+N more" summary) glued
   * to the input box. The empty string gives the "Todos" panel a little
   * breathing room.
   */
  private withTrailingSpacer(lines: string[]): string[] {
    if (lines.length === 0) return lines;
    lines.push("");
    return lines;
  }

  dispose(): void {
    if (this.uiCtx) this.uiCtx.setWidget(WIDGET_KEY, undefined);
    this.widgetRegistered = false;
    this.tui = undefined;
    this.uiCtx = undefined;
    this.collapsed = false;
    this.resetCompletedDisplayState();
  }
}
