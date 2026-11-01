import { ToolExecutionComponent } from "@earendil-works/pi-coding-agent";
import { Container } from "@earendil-works/pi-tui";
import { keepsNative, splitNative } from "./nested.js";

const APPLIED = Symbol.for("pi-quiet-tools.keep-native");
// shortcut: markers stores its saved render on these symbols; if it renames them, background rows stay one JSON line.
const PRESENTATION = Symbol.for("kg.pi.toolPresentation.v3");
const GROUPING = Symbol.for("kg.pi.toolGrouping.v1");

type Row = {
  toolName?: string;
  args?: unknown;
  getRenderShell?: () => string;
  render?: (width: number) => string[];
};

type Height = { component: unknown; height: number };
type Host = {
  children?: unknown[];
  mouseLayout?: { width: number; children: Height[] };
  render?: (this: Host, width: number) => string[];
};

/** Let pi-background draw bg_run, bg_status, and bg_kill, including the nested └ line. */
export function installKeepNative(): void {
  const toolProto = ToolExecutionComponent.prototype as Row & {
    render?: (this: Row, width: number) => string[];
    [APPLIED]?: boolean;
    [PRESENTATION]?: { originalRender?: (this: Row, width: number) => string[] };
  };
  if (toolProto[APPLIED]) return;
  const nativeRender = toolProto[PRESENTATION]?.originalRender;
  const containerProto = Container.prototype as Host & { [GROUPING]?: unknown };
  if (typeof nativeRender !== "function" || !containerProto[GROUPING] || typeof containerProto.render !== "function")
    return;

  const markersToolRender = toolProto.render;
  const markersContainerRender = containerProto.render;
  toolProto.render = function (this: Row, width: number) {
    if (keepsNative(this)) return nativeRender.call(this, width);
    return markersToolRender?.call(this, width) ?? nativeRender.call(this, width);
  };
  containerProto.render = function (this: Host, width: number) {
    const children = this.children;
    if (!Array.isArray(children) || !children.some((child) => keepsNative(child as Row))) {
      return markersContainerRender.call(this, width);
    }
    const lines: string[] = [];
    const heights: Height[] = [];
    for (const part of splitNative(children.map((child) => ({ native: keepsNative(child as Row), child })))) {
      if ("native" in part) {
        const child = part.native.child as Row;
        const drawn = child.render?.(width) ?? [];
        lines.push(...drawn);
        heights.push({ component: child, height: drawn.length });
        continue;
      }
      this.children = part.grouped.map((item) => item.child);
      lines.push(...markersContainerRender.call(this, width));
      heights.push(
        ...(this.mouseLayout?.children ?? part.grouped.map((item) => ({ component: item.child, height: 1 }))),
      );
    }
    this.children = children;
    this.mouseLayout = { width, children: heights };
    return lines;
  };
  toolProto[APPLIED] = true;
}
