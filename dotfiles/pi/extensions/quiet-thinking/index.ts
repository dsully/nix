import { AssistantMessageComponent, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { collapseThinking, presentThought, thinkingLine, type Part, type ThinkingBlock } from "./label.js";

const ORIGINAL = Symbol.for("pi-quiet-thinking.planContent");

type PlanContent = (message: unknown) => Part[];
type Planner = {
  planContent?: PlanContent;
  hiddenThinkingLabel?: string;
  [ORIGINAL]?: PlanContent;
};

/** One thought row per message, showing its first line instead of a stack of "│ * Thought". Ctrl+T still expands. */
export default function quietThinking(_pi: ExtensionAPI) {
  const proto = AssistantMessageComponent.prototype as unknown as Planner;
  const original = (proto[ORIGINAL] ??= proto.planContent);
  // shortcut: patches a private method; if a pi update renames it, the Thought stack stays.
  if (typeof original !== "function") return;
  proto.planContent = function (this: Planner, message) {
    const line = thinkingLine((message as { content?: ThinkingBlock[] } | undefined)?.content);
    const presented = presentThought(this.hiddenThinkingLabel, line);
    if (presented) this.hiddenThinkingLabel = presented;
    return collapseThinking(original.call(this, message));
  };
}
