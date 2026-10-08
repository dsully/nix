import { join } from "node:path";
import { getAgentDir, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { createDraftStore } from "./src/input/store.js";
import { registerFooter } from "./src/runtime/runtime.js";

export default function footer(pi: ExtensionAPI): void {
  registerFooter(pi, createDraftStore(join(getAgentDir(), "pi-footer", "drafts")));
}
