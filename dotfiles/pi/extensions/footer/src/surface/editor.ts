import type { CustomEditor, KeybindingsManager, Theme } from "@earendil-works/pi-coding-agent";
import { isKeyRepeat, matchesKey, truncateToWidth, visibleWidth, type Component, type EditorComponent, type OverlayHandle, type OverlayOptions, type TUI } from "@earendil-works/pi-tui";
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

function removeBorderColor(line: string, borderColor: (text: string) => string): string {
  const sample = borderColor("─");
  const markerIndex = sample ? sample.indexOf("─") : -1;
  if (markerIndex < 0) return line;
  const prefix = sample.slice(0, markerIndex);
  const suffix = sample.slice(markerIndex + 1);
  let out = line;
  if (prefix) out = out.split(prefix).join("");
  if (suffix) out = out.split(suffix).join("");
  return out;
}

function stripBorderColor(line: string, borderColor: (text: string) => string): string {
  return stripControls(removeBorderColor(line, borderColor));
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

type WorkingIndicator = Parameters<CustomEditor["setWorkingStatusIndicator"]>[0];

/** The pi-tui editor members the frame reads; any EditorComponent may lack the optional ones. */
type InnerEditor = EditorComponent & {
  focused?: boolean;
  onExtensionShortcut?: (data: string) => boolean | undefined;
  getPaddingX?(): number;
  handleMouse?(event: object): object | undefined;
  renderedVisibleLineCount?: number;
};

/** The proxy from forwardToInner supplies these members from the inner editor. */
export interface FooterEditor extends EditorComponent {}

/**
 * Members the frame does not define go to the inner editor: pi wires callbacks and
 * action handlers onto the editor by duck typing, so they must land there.
 */
function forwardToInner(frame: FooterEditor, inner: InnerEditor): FooterEditor {
  const target = inner as unknown as Record<PropertyKey, unknown>;
  return new Proxy(frame, {
    get(own, prop, receiver) {
      if (prop in own) return Reflect.get(own, prop, receiver);
      const value = target[prop];
      return typeof value === "function" ? value.bind(inner) : value;
    },
    set(own, prop, value, receiver) {
      if (prop in own) return Reflect.set(own, prop, value, receiver);
      target[prop] = value;
      return true;
    },
    has: (own, prop) => prop in own || prop in target,
  });
}

/**
 * Frames whatever editor the previous factory produced, so editor layers from other
 * extensions (prompt history, keymaps) keep working regardless of load order.
 * Every field needs an initializer: the proxy routes a property to the frame only if it exists here.
 */
export class FooterEditor implements Component {
  readonly embedWorkingStatus = true;
  private disposed = false;
  private activityIndicator: WorkingIndicator = undefined;
  private readonly statusLine = new StatusLineRenderer();
  private pasting = false;
  private acLines: string[] = [];
  private acIndent = 0;
  private acEditorWidth = 0;
  private acFresh = false;
  private acOverlay: OverlayHandle | undefined = undefined;
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
      const result = this.inner.handleMouse?.({
        ...event,
        x: event.x - this.acIndent,
        y: (this.inner.renderedVisibleLineCount ?? 0) + 2 + event.y,
        width: this.acEditorWidth,
      });
      return result && { ...result, focus: false };
    },
  };

  private readonly inner: InnerEditor;

  constructor(
    private readonly tui: TUI,
    inner: EditorComponent,
    private readonly appKeybindings: KeybindingsManager,
    private readonly getState: () => FooterState,
    private readonly footerOptions: FooterEditorOptions,
  ) {
    this.inner = inner as InnerEditor;
    // biome-ignore lint/correctness/noConstructorReturn: callers must receive the forwarding proxy, not the bare frame.
    return forwardToInner(this, this.inner);
  }

  dispose(): void {
    this.disposed = true;
    this.activityIndicator = undefined;
    this.hideAutocompleteOverlay();
  }

  setWorkingStatusIndicator(indicator: WorkingIndicator): void {
    // Pi owns the indicator and its clock. The footer renders it only in its own frame.
    if (!this.disposed) this.activityIndicator = indicator;
  }

  handleInput(data: string): void {
    if (this.pasting || data.includes("\x1b[200~")) {
      // A fragmented bracketed paste is text, even when a chunk looks like a shortcut.
      if (data.includes("\x1b[200~")) this.pasting = true;
      const end = data.indexOf("\x1b[201~");
      const length = end < 0 ? data.length : end + 6;
      this.inner.handleInput(data.slice(0, length));
      if (end >= 0) this.pasting = false;
      if (length < data.length) this.handleInput(data.slice(length));
      return;
    }
    const stash = this.footerOptions.stash;
    if (this.inner.focused && stash && matchesKey(data, STASH_SHORTCUT)) {
      if (isKeyRepeat(data)) return;
      const conflict = shortcutConflict(data, STASH_SHORTCUT, this.appKeybindings);
      if (conflict) {
        this.footerOptions.onStashError?.(`Stash shortcut ${STASH_SHORTCUT} is used by ${conflict}.`);
      } else {
        // Existing extension shortcuts retain precedence over this editor feature.
        if (this.inner.onExtensionShortcut?.(data)) return;
        const current = this.inner.getExpandedText?.() ?? this.inner.getText();
        let restored: string;
        try {
          restored = stash.exchange(current);
        } catch {
          this.footerOptions.onStashError?.("Could not save the draft. Input was kept.");
          return;
        }
        if (current !== restored) this.inner.setText(restored);
        this.tui.requestRender();
        return;
      }
    }
    this.inner.handleInput(data);
  }

  invalidate(): void {
    this.inner.invalidate();
  }

  // Pi assigns borderColor on the editor (thinking level, Bash mode); the proxy stores it on the inner editor.
  private frameBorder(): (text: string) => string {
    return this.inner.borderColor ?? ((text) => text);
  }

  private extractScrollIndicator(line: string, width: number): string | undefined {
    return formatSurfaceScrollIndicator(stripBorderColor(line, this.frameBorder()), width);
  }

  render(width: number): string[] {
    const metrics = measureInputSurfaceFrame(width);
    // Pi 1.0 still recurses on a wide grapheme in a one-column layout.
    // Reserve two columns plus the native padding/cursor, then clip the frame.
    const editorWidth = Math.max(metrics.editorContentWidth, 3, 2 + (this.inner.getPaddingX?.() ?? 0) * 2);
    const lines = this.inner.render(editorWidth);
    if (lines.length < 2) return lines;

    const border = this.frameBorder();
    const topOriginal = lines[0] ?? "";
    let bottomIndex = -1;
    for (let i = 1; i < lines.length; i++) {
      if (isHorizontalBorder(lines[i] ?? "", border)) bottomIndex = i;
    }
    if (bottomIndex < 1) return lines;

    const bottomOriginal = lines[bottomIndex] ?? "";
    const state = this.getState();
    const styles = stylesFor(this.footerOptions.getTheme());
    const activity = this.activityIndicator;
    const frame = renderInputSurfaceFrame({
      state,
      width,
      styles: { ...styles, border },
      lines: lines.slice(1, bottomIndex),
      focused: this.inner.focused ?? false,
      activity: activity && { kind: activity.kind, render: w => removeBorderColor(activity.renderInBorder(w), border) },
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
