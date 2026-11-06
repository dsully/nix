import { AssistantMessageComponent, ToolExecutionComponent, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { patchMethod } from "../lib/patch.js";
import { codeRender } from "./code-render.js";
import { collapseThinking, presentThought, thinkingLine, type Part, type ThinkingBlock } from "./label.js";
import { installKeepNative } from "./native.js";
import { nestedResultRenderer } from "./render.js";
import { usesPiFallback } from "./subagent.js";
import { thoughtToolRows } from "./grouping.js";

const CHAT_CONTAINER_HOOKS = Symbol.for("kg.pi.chatContainerHooks.v1");
const TRANSCRIPT_HOOK = Symbol.for("pi-transcript.thoughtGroupingHook.v1");
const THOUGHT_GROUP = Symbol.for("pi-transcript.thoughtGroup.v1");
type ContainerHook = (container: object, children: unknown[], width: number) => (() => void) | undefined;
type Planner = { hiddenThinkingLabel?: string };
type Execution = { toolName: string; args: unknown };

function installThoughtGrouping(): void {
  const globals = globalThis as Record<symbol, unknown>;
  let hooks = globals[CHAT_CONTAINER_HOOKS] as Set<ContainerHook> | undefined;
  if (!hooks) {
    hooks = new Set();
    globals[CHAT_CONTAINER_HOOKS] = hooks;
  }
  hooks.delete(globals[TRANSCRIPT_HOOK] as ContainerHook);
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

// shortcut: both patch private renderer methods; if Pi or markers renames them, these are skipped.
function collapseSubagentResults(): void {
  patchMethod<(this: Execution) => unknown>(
    ToolExecutionComponent.prototype,
    "getResultRenderer",
    "pi-transcript.getResultRenderer",
    (original) =>
      original &&
      function (this: Execution) {
        return usesPiFallback(this.toolName, this.args) ? nestedResultRenderer : original.call(this);
      },
  );
}

function installThinkingRenderer(): void {
  patchMethod<(this: Planner, message: unknown) => Part[]>(
    AssistantMessageComponent.prototype,
    "planContent",
    "pi-transcript.planContent",
    (original) =>
      original &&
      function (this: Planner, message: unknown) {
        const line = thinkingLine((message as { content?: ThinkingBlock[] } | undefined)?.content);
        const presented = presentThought(this.hiddenThinkingLabel, line);
        if (presented) this.hiddenThinkingLabel = presented;
        return collapseThinking(original.call(this, message));
      },
  );
}

export default function transcript(pi: ExtensionAPI) {
  installThinkingRenderer();
  installThoughtGrouping();
  collapseSubagentResults();
  installKeepNative();
  pi.on("session_start", () => installKeepNative());
  codeRender(pi);
}
