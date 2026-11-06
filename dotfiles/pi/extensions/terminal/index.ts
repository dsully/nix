import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { ghosttyStatus } from "./ghostty.js";
import { questionStatus } from "./question.js";
import { stripTitlePrefix } from "./title.js";

export default function terminal(pi: ExtensionAPI) {
  stripTitlePrefix();
  questionStatus(pi);
  ghosttyStatus(pi);
}
