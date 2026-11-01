import { AssistantMessageComponent, ToolExecutionComponent, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { collapseThinking, presentThought, thinkingLine, type Part, type ThinkingBlock } from "./label.js";
import { installKeepNative } from "../quiet-tools/native.js";
import { nestedResultRenderer } from "../quiet-tools/render.js";
import { usesPiFallback } from "../quiet-tools/subagent.js";

const PLAN_ORIGINAL = Symbol.for("pi-quiet-thinking.planContent");
const RESULT_ORIGINAL = Symbol.for("pi-quiet-tools.getResultRenderer");

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
  collapseSubagentResults();
  installKeepNative();
  _pi.on("session_start", () => installKeepNative());
}
