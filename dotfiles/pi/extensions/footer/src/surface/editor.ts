import { CustomEditor, type KeybindingsManager, type Theme } from "@earendil-works/pi-coding-agent";
import { isKeyRepeat, matchesKey, truncateToWidth, visibleWidth, type Component, type EditorTheme, type OverlayHandle, type OverlayOptions, type TUI } from "@earendil-works/pi-tui";
import { shortcutConflict } from "../input/keybinding.js";
import type { PromptStash } from "../input/stash.js";
import { stripControls } from "./format.js";
import { measureInputSurfaceFrame, renderInputSurfaceFrame, STASH_SHORTCUT } from "./frame.js";
import { StatusLineRenderer } from "./status-line.js";
import { formatSurfaceScrollIndicator } from "./layout.js";
import { stylesFor } from "../theme.js";
import type { FooterState } from "../types.js";

export interface FooterEditorOptions {
  readonly getTheme: () => Theme;
  readonly stash?: PromptStash;
  readonly onStashError?: (message: string) => void;
}

function stripBorderColor(line: string, borderColor: (text: string) => string): string {
  const sample = borderColor("─");
  if (!sample || sample === "─") return stripControls(line);
  const markerIndex = sample.indexOf("─");
  if (markerIndex < 0) return stripControls(line);
  const prefix = sample.slice(0, markerIndex);
  const suffix = sample.slice(markerIndex + 1);
  let out = line;
  if (prefix) out = out.split(prefix).join("");
  if (suffix) out = out.split(suffix).join("");
  return stripControls(out);
}

function isHorizontalBorder(line: string, borderColor: (text: string) => string): boolean {
  const plain = stripBorderColor(line, borderColor).trim();
  if (plain.length === 0) return false;
  const borderCharactersOnly = [...plain].every(
    (char) => char === "─" || char === "↑" || char === "↓" || char === " " || char === "." || /[0-9a-z]/i.test(char),
  );
  if (!borderCharactersOnly) return false;
  // Pi truncates scroll borders with ASCII periods at very narrow widths,
  // including pure "." / "..." lines where no horizontal glyph survives.
  return plain.includes("─") || /^\.+$/.test(plain);
}

function normalizeRenderedLine(line: string, width: number): string {
  const lineWidth = visibleWidth(line);
  if (lineWidth === width) return line;
  if (lineWidth < width) return `${line}${" ".repeat(width - lineWidth)}`;
  return truncateToWidth(line, width, "");
}

export class FooterEditor extends CustomEditor {
  private disposed = false;
  private activityIndicator: Parameters<CustomEditor["setWorkingStatusIndicator"]>[0];
  private readonly statusLine = new StatusLineRenderer();
  private pasting = false;
  private acLines: string[] = [];
  private acIndent = 0;
  private acEditorWidth = 0;
  private acFresh = false;
  private acOverlay: OverlayHandle | undefined;
  private readonly acOptions: OverlayOptions = { anchor: "bottom-left", nonCapturing: true };
  private readonly acComponent: Component & { handleMouse(event: { x: number; y: number }): unknown } = {
    // The editor renders before overlays every frame; a stale list means it was unmounted.
    render: () => {
      if (!this.acFresh) {
        this.hideAutocompleteOverlay();
        return [];
      }
      this.acFresh = false;
      return this.acLines;
    },
    invalidate: () => { },
    // Translate into the base editor's coordinates, where the list sits below its bottom border.
    handleMouse: (event) => {
      const ed = this as unknown as {
        handleMouse?(e: object): object | undefined;
        renderedVisibleLineCount: number;
      };
      const result = ed.handleMouse?.({
        ...event,
        x: event.x - this.acIndent,
        y: ed.renderedVisibleLineCount + 2 + event.y,
        width: this.acEditorWidth,
      });
      return result && { ...result, focus: false };
    },
  };

  constructor(
    tui: TUI,
    theme: EditorTheme,
    private readonly appKeybindings: KeybindingsManager,
    private readonly getState: () => FooterState,
    private readonly footerOptions: FooterEditorOptions,
  ) {
    super(tui, theme, appKeybindings, { embedWorkingStatus: true });
  }

  dispose(): void {
    this.disposed = true;
    this.activityIndicator = undefined;
    this.hideAutocompleteOverlay();
  }

  override setWorkingStatusIndicator(indicator: Parameters<CustomEditor["setWorkingStatusIndicator"]>[0]): void {
    // Pi owns the indicator and its clock. The footer renders it only in its own frame.
    if (!this.disposed) this.activityIndicator = indicator;
  }

  handleInput(data: string): void {
    if (this.pasting || data.includes("\x1b[200~")) {
      // A fragmented bracketed paste is text, even when a chunk looks like a shortcut.
      if (data.includes("\x1b[200~")) this.pasting = true;
      const end = data.indexOf("\x1b[201~");
      const length = end < 0 ? data.length : end + 6;
      super.handleInput(data.slice(0, length));
      if (end >= 0) this.pasting = false;
      if (length < data.length) this.handleInput(data.slice(length));
      return;
    }
    const stash = this.footerOptions.stash;
    if (this.focused && stash && matchesKey(data, STASH_SHORTCUT)) {
      if (isKeyRepeat(data)) return;
      const conflict = shortcutConflict(data, STASH_SHORTCUT, this.appKeybindings);
      if (conflict) {
        this.footerOptions.onStashError?.(`Stash shortcut ${STASH_SHORTCUT} is used by ${conflict}.`);
      } else {
        // Existing extension shortcuts retain precedence over this editor feature.
        if (this.onExtensionShortcut?.(data)) return;
        const current = this.getExpandedText();
        let restored: string;
        try {
          restored = stash.exchange(current);
        } catch {
          this.footerOptions.onStashError?.("Could not save the draft. Input was kept.");
          return;
        }
        if (current !== restored) this.setText(restored);
        this.tui.requestRender();
        return;
      }
    }
    super.handleInput(data);
  }

  private extractScrollIndicator(line: string, width: number): string | undefined {
    return formatSurfaceScrollIndicator(stripBorderColor(line, this.borderColor), width);
  }

  render(width: number): string[] {
    const metrics = measureInputSurfaceFrame(width);
    // Pi 1.0 still recurses on a wide grapheme in a one-column layout.
    // Reserve two columns plus the native padding/cursor, then clip the frame.
    const editorWidth = Math.max(metrics.editorContentWidth, 3, 2 + this.getPaddingX() * 2);
    const lines = super.render(editorWidth);
    if (lines.length < 2) return lines;

    const topOriginal = lines[0] ?? "";
    let bottomIndex = -1;
    for (let i = 1; i < lines.length; i++) {
      if (isHorizontalBorder(lines[i] ?? "", this.borderColor)) bottomIndex = i;
    }
    if (bottomIndex < 1) return lines;

    const bottomOriginal = lines[bottomIndex] ?? "";
    const state = this.getState();
    const styles = stylesFor(this.footerOptions.getTheme());
    const activity = this.activityIndicator;
    const frame = renderInputSurfaceFrame({
      state,
      width,
      // Pi sets borderColor for thinking level and Bash mode.
      styles: { ...styles, border: this.borderColor },
      lines: lines.slice(1, bottomIndex),
      focused: this.focused,
      activity: activity && { kind: activity.kind, render: w => activity.renderInBorder(w) },
      topScrollIndicator: this.extractScrollIndicator(topOriginal, metrics.safeWidth),
      bottomScrollIndicator: this.extractScrollIndicator(bottomOriginal, metrics.safeWidth),
      hasDraft: this.footerOptions.stash?.hasDraft,
      status: budget => this.statusLine.render(state, budget, styles),
    });

    const indent = " ".repeat(metrics.autocompleteIndent);
    const acLines = lines.slice(bottomIndex + 1).map(line => normalizeRenderedLine(`${indent}${line}`, metrics.safeWidth));
    if (this.tui.mode !== "fullscreen") return [...frame, ...acLines];
    this.acIndent = metrics.autocompleteIndent;
    this.acEditorWidth = editorWidth;
    this.syncAutocompleteOverlay(acLines, frame.length, metrics.safeWidth);
    return frame;
  }

  /**
   * Fullscreen pins the dock to the bottom row, so a bottom-anchored overlay
   * lands exactly above the frame without resizing the dock or transcript.
   */
  private syncAutocompleteOverlay(acLines: string[], frameHeight: number, width: number): void {
    this.acLines = acLines;
    this.acFresh = true;
    if (acLines.length === 0) {
      this.hideAutocompleteOverlay();
      return;
    }
    this.acOptions.width = width;
    this.acOptions.offsetY = -(frameHeight + this.linesBelowEditor());
    this.acOverlay ??= this.tui.showOverlay(this.acComponent, this.acOptions);
  }

  private hideAutocompleteOverlay(): void {
    this.acOverlay?.hide();
    this.acOverlay = undefined;
  }

  private linesBelowEditor(): number {
    const kids = this.tui.children;
    const i = kids.findIndex(c => c === this || (c as { children?: unknown[] }).children?.includes(this));
    if (i < 0) return 0;
    const w = this.tui.terminal.columns;
    return kids.slice(i + 1).reduce((n, c) => n + c.render(w).length, 0);
  }
}
