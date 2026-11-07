/**
 * Deactivates tools whose job another declared tool already does, or that cannot work in this session, to save prompt tokens,
 * and condenses rules that repeat tool descriptions.
 * Leaves toolSnippets alone: pi rebuilds the prompt with them after the first call, so removing them busts the prompt cache every turn.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const redundant = [
  "batch_web_fetch", // codemode + Promise.allSettled over web_fetch
  "ffgrep", // hashline grep
  // Their slash commands cover these; review_output stays, /supi-review tells the model to page long reports with it.
  "cache_forensics",
  "review_run",
  // pi-superagents registers these unconditionally; they need Plannotator, which is not installed.
  "superpowers_plan_review",
  "superpowers_spec_review",
];

// pi-superagents' child-only lifecycle tools; it sets PI_SUBAGENT_SESSION in children.
const childOnly = ["subagent_done", "caller_ping"];

// Replaces each tool's rules.
const rules: Record<string, string[]> = {
  // fffind: [
  //   "fffind is for paths; use grep for content. Keep patterns to 1-2 terms.",
  //   "Exact file: path '**/name.ext'. Whole directory: path 'dir/**' with an empty pattern.",
  // ],
};

export function toolDiet(pi: ExtensionAPI) {
  const hidden = new Set(process.env.PI_SUBAGENT_SESSION ? redundant : [...redundant, ...childOnly]);

  // Not session_start: pi-fff re-activates its tools from its own session_start handler.
  pi.on("before_agent_start", (event) => {
    const active = pi.getActiveTools();
    if (active.some((name) => hidden.has(name))) pi.setActiveTools(active.filter((name) => !hidden.has(name)));

    const options = event.systemPromptOptions as { toolGuidelines?: Record<string, string[]> };
    if (options.toolGuidelines) Object.assign(options.toolGuidelines, rules);
  });
}
