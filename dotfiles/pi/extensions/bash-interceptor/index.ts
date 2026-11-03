import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { interception } from "./interceptor.js";

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event) => {
    if (event.toolName !== "bash") return;
    const command = (event.input as { command?: unknown }).command;
    if (typeof command !== "string") return;
    const reason = interception(command, pi.getActiveTools());
    if (reason) return { block: true, reason };
  });
}
