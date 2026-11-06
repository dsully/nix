import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { claudeMd } from "./claude-md.js";
import { inspectSystemPrompt } from "./inspect.js";
import { toolDiet } from "./tool-diet.js";

export default function systemPrompt(pi: ExtensionAPI) {
  claudeMd(pi);
  toolDiet(pi);
  inspectSystemPrompt(pi);
}
