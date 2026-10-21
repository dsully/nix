/**
 * Deactivates tools whose job another declared tool already does, or that cannot work in this session, to save prompt tokens,
 * and repoints fffind's "use ffgrep" guideline at grep.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const redundant = [
  "batch_web_fetch", // codemode + Promise.allSettled over web_fetch
  "ffgrep", // hashline grep
  "global_memory_search", // memory_search already defaults to scope "all"
  // pi-superagents registers these unconditionally; they need Plannotator, which is not installed.
  "superpowers_plan_review",
  "superpowers_spec_review",
];

// pi-superagents' child-only lifecycle tools; it sets PI_SUBAGENT_SESSION in children.
const childOnly = ["subagent_done", "caller_ping"];

export default function (pi: ExtensionAPI) {
  const hidden = new Set(process.env.PI_SUBAGENT_SESSION ? redundant : [...redundant, ...childOnly]);

  // Not session_start: pi-fff re-activates its tools from its own session_start handler.
  pi.on("before_agent_start", (event) => {
    const active = pi.getActiveTools();
    if (active.some((name) => hidden.has(name))) pi.setActiveTools(active.filter((name) => !hidden.has(name)));

    const guidelines = event.systemPromptOptions.toolGuidelines as Record<string, string[]> | undefined;
    if (guidelines?.fffind) guidelines.fffind = guidelines.fffind.map((line) => line.replace("Use ffgrep for content", "Use grep for content"));
  });
}
