import { AssistantMessageComponent, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { dropHiddenThinking, type Part } from "./plan.js";

const ORIGINAL = Symbol.for("pi-quiet-thinking.planContent");

type PlanContent = (message: unknown) => Part[];
type Planner = { planContent?: PlanContent; [ORIGINAL]?: PlanContent };

/** hideThinkingBlock leaves a "Thinking..." line per tool round; drop it. Ctrl+T still expands thinking. */
export default function (_pi: ExtensionAPI) {
  const proto = AssistantMessageComponent.prototype as unknown as Planner;
  const original = (proto[ORIGINAL] ??= proto.planContent);
  // shortcut: patches a private method; if a pi update renames it, this silently does nothing.
  if (typeof original !== "function") return;
  proto.planContent = function (this: unknown, message) {
    return dropHiddenThinking(original.call(this, message));
  };
}
