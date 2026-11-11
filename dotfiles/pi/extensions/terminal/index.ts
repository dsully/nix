import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { ghosttyStatus } from "./ghostty.js";
import { stripTitlePrefix } from "./title.js";

export default function terminal(pi: ExtensionAPI) {
  stripTitlePrefix();
  ghosttyStatus(pi);
}
