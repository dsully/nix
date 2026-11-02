import { AssistantMessageComponent, ToolExecutionComponent, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { collapseThinking, presentThought, thinkingLine, type Part, type ThinkingBlock } from "./label.js";
import { installKeepNative } from "./native.js";
import { nestedResultRenderer } from "./render.js";
import { usesPiFallback } from "./subagent.js";
import { thoughtToolRows } from "./grouping.js";

const PLAN_ORIGINAL = Symbol.for("pi-quiet-thinking.planContent");
const RESULT_ORIGINAL = Symbol.for("pi-quiet-tools.getResultRenderer");

const CHAT_CONTAINER_HOOKS = Symbol.for("kg.pi.chatContainerHooks.v1");
const TRANSCRIPT_HOOK = Symbol.for("pi-transcript.thoughtGroupingHook.v1");
const THOUGHT_GROUP = Symbol.for("pi-transcript.thoughtGroup.v1");
type ContainerHook = (container: object, children: unknown[], width: number) => (() => void) | undefined;
type PlanContent = (message: unknown) => Part[];
type Planner = {
  planContent?: PlanContent;
  hiddenThinkingLabel?: string;
  [PLAN_ORIGINAL]?: PlanContent;
};
type GetRenderer = () => unknown;
type Execution = {
  toolName: string;
  args: unknown;
  getResultRenderer?: GetRenderer;
  [RESULT_ORIGINAL]?: GetRenderer;
};

function installThoughtGrouping(): void {
  const globals = globalThis as Record<symbol, unknown>;
  const existing = globals[TRANSCRIPT_HOOK] as ContainerHook | undefined;
  if (existing) return;

  let hooks = globals[CHAT_CONTAINER_HOOKS] as Set<ContainerHook> | undefined;
  if (!hooks) {
    hooks = new Set();
    globals[CHAT_CONTAINER_HOOKS] = hooks;
  }
  const hook: ContainerHook = (_container, children) => {
    const previous = new Map<object, { present: boolean; value: unknown }>();
    for (const [row, last] of thoughtToolRows(children)) {
      const target = row as Record<symbol, unknown>;
      previous.set(row, { present: Object.hasOwn(row, THOUGHT_GROUP), value: target[THOUGHT_GROUP] });
      target[THOUGHT_GROUP] = { last };
    }
    return () => {
      for (const [row, original] of previous) {
        const target = row as Record<symbol, unknown>;
        if (original.present) target[THOUGHT_GROUP] = original.value;
        else delete target[THOUGHT_GROUP];
      }
    };
  };
  hooks.add(hook);
  globals[TRANSCRIPT_HOOK] = hook;
}

function collapseSubagentResults(): void {
  const proto = ToolExecutionComponent.prototype as unknown as Execution;
  const original = (proto[RESULT_ORIGINAL] ??= proto.getResultRenderer);
  // Shortcut: patches private renderer methods; update if Pi or markers renames them.
  if (typeof original !== "function") return;
  proto.getResultRenderer = function (this: Execution) {
    return usesPiFallback(this.toolName, this.args) ? nestedResultRenderer : original.call(this);
  };
}

function installThinkingRenderer(): void {
  const proto = AssistantMessageComponent.prototype as unknown as Planner;
  const original = (proto[PLAN_ORIGINAL] ??= proto.planContent);
  // Shortcut: patches private renderer methods; update if Pi or markers renames them.
  if (typeof original !== "function") return;
  proto.planContent = function (this: Planner, message) {
    const line = thinkingLine((message as { content?: ThinkingBlock[] } | undefined)?.content);
    const presented = presentThought(this.hiddenThinkingLabel, line);
    if (presented) this.hiddenThinkingLabel = presented;
    return collapseThinking(original.call(this, message));
  };
}

export default function transcript(_pi: ExtensionAPI) {
  installThinkingRenderer();
  installThoughtGrouping();
  collapseSubagentResults();
  installKeepNative();
  _pi.on("session_start", () => installKeepNative());
}
