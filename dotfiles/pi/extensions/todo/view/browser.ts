import type { Theme } from "@earendil-works/pi-coding-agent";
import { type Component, Key, matchesKey, type TUI, truncateToWidth } from "@earendil-works/pi-tui";
import type { TaskState } from "../state/state.js";
import { type BrowserRow, browserRows, liveChildren } from "../state/task-graph.js";
import { sanitizeTerminalText } from "../tool/sanitize.js";
import { formatOverlayTaskLine, formatStatusLabel } from "./format.js";

/** Read-only `/todos` overlay; re-reads state on every render so it follows the agent's edits. */
export class TodoBrowser implements Component {
  private readonly folded = new Set<number>();
  private selectedId: number | undefined;
  private scroll = 0;

  constructor(
    private readonly tui: TUI,
    private readonly theme: Theme,
    private readonly getState: () => TaskState,
    private readonly done: () => void,
  ) {
    this.selectedId = getState().tasks.find((t) => t.status === "in_progress")?.id;
  }

  private rows(): BrowserRow[] {
    const rows = browserRows(this.getState().tasks, this.folded);
    if (!rows.some((row) => row.task.id === this.selectedId)) this.selectedId = rows[0]?.task.id;
    return rows;
  }

  private viewHeight(): number {
    return Math.max(3, Math.floor(this.tui.terminal.rows * 0.7) - 4);
  }

  handleInput(data: string): void {
    if (matchesKey(data, Key.escape) || matchesKey(data, Key.ctrl("c")) || data === "q") return this.done();
    const rows = this.rows();
    const index = rows.findIndex((row) => row.task.id === this.selectedId);
    const row = rows[index];
    if (!row) return;
    const select = (i: number) => {
      this.selectedId = rows[Math.max(0, Math.min(rows.length - 1, i))]?.task.id;
    };

    if (matchesKey(data, Key.up) || data === "k") select(index - 1);
    else if (matchesKey(data, Key.down) || data === "j") select(index + 1);
    else if (matchesKey(data, Key.pageUp)) select(index - this.viewHeight());
    else if (matchesKey(data, Key.pageDown)) select(index + this.viewHeight());
    else if (matchesKey(data, Key.home)) select(0);
    else if (matchesKey(data, Key.end)) select(rows.length - 1);
    else if (matchesKey(data, Key.left) || data === "h") {
      if (row.hasChildren && !this.folded.has(row.task.id)) this.folded.add(row.task.id);
      else if (row.task.parentId !== undefined && rows.some((r) => r.task.id === row.task.parentId))
        this.selectedId = row.task.parentId;
    } else if (matchesKey(data, Key.right) || data === "l") {
      if (this.folded.has(row.task.id)) this.folded.delete(row.task.id);
      else if (row.hasChildren) select(index + 1);
    } else if (matchesKey(data, Key.enter) || matchesKey(data, Key.space)) {
      if (row.hasChildren && !this.folded.delete(row.task.id)) this.folded.add(row.task.id);
    } else return;
    this.tui.requestRender();
  }

  render(width: number): string[] {
    const { theme } = this;
    const state = this.getState();
    const rows = this.rows();
    const inner = Math.max(10, width - 4);
    const height = this.viewHeight();
    const selected = Math.max(
      0,
      rows.findIndex((row) => row.task.id === this.selectedId),
    );
    if (selected < this.scroll) this.scroll = selected;
    if (selected >= this.scroll + height) this.scroll = selected - height + 1;
    this.scroll = Math.max(0, Math.min(this.scroll, rows.length - height));

    const body = rows.slice(this.scroll, this.scroll + height).map((row) => {
      const children = liveChildren(state.tasks, row.task.id);
      const progress = { done: children.filter((c) => c.status === "completed").length, total: children.length };
      const arrow = row.hasChildren ? (this.folded.has(row.task.id) ? "▸ " : "▾ ") : "  ";
      const line = `${"  ".repeat(row.depth)}${theme.fg("dim", arrow)}${formatOverlayTaskLine(row.task, theme, true, progress)}`;
      return row.task.id === this.selectedId ? theme.bg("selectedBg", line) : line;
    });

    const current = rows[selected]?.task;
    const detail = current
      ? theme.fg(
          "muted",
          [`#${current.id}`, formatStatusLabel(current.status), current.description]
            .filter(Boolean)
            .map((part) => sanitizeTerminalText(String(part)))
            .join(" · "),
        )
      : "";

    const live = state.tasks.filter((t) => t.status !== "deleted");
    const doneCount = live.filter((t) => t.status === "completed").length;
    const position =
      rows.length > height ? ` ${this.scroll + 1}-${Math.min(rows.length, this.scroll + height)}/${rows.length}` : "";
    const edge = (left: string, label: string, right: string) =>
      theme.fg("border", `${left}${truncateToWidth(`─ ${label} ${"─".repeat(width)}`, width - 2, "")}${right}`);
    const side = theme.fg("border", "│");
    const pad = (line: string) => `${side} ${truncateToWidth(line, inner, "…", true)} ${side}`;

    return [
      edge("╭", `Todos (${doneCount}/${live.length})${position}`, "╮"),
      ...body.map(pad),
      pad(""),
      pad(detail),
      edge("╰", "↑↓ move · ←→ fold · enter toggle · esc close", "╯"),
    ];
  }

  invalidate(): void {}
}
