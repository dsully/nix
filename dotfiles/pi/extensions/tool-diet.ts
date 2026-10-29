/**
 * Deactivates tools whose job another declared tool already does, or that cannot work in this session, to save prompt tokens,
 * and condenses rules that repeat tool descriptions.
 * Leaves toolSnippets alone: pi rebuilds the prompt with them after the first call, so removing them busts the prompt cache every turn.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const redundant = [
  "batch_web_fetch", // codemode + Promise.allSettled over web_fetch
  "ffgrep", // hashline grep
  // pi-superagents registers these unconditionally; they need Plannotator, which is not installed.
  "superpowers_plan_review",
  "superpowers_spec_review",
];

// pi-superagents' child-only lifecycle tools; it sets PI_SUBAGENT_SESSION in children.
const childOnly = ["subagent_done", "caller_ping"];

// Replaces each tool's rules.
const rules: Record<string, string[]> = {
  bg_run: [
    "Use bg_run, not bash, for anything that may run past ~30s (downloads, installs, builds, test suites, servers, watchers); keep bash for quick commands whose output you need now.",
    "bg_run's exit message (code + log tail) arrives on its own: never sleep, poll, or tail its log. To react to output while it runs, pass wake_on with a regex.",
    "Don't redirect bg_run output; it already logs. bash times out after 2 minutes unless you pass timeout (max 10).",
  ],
  bg_status: [],
  bg_kill: [],
  fffind: [
    "fffind is for paths; use grep for content. Keep patterns to 1-2 terms.",
    "Exact file: path '**/name.ext'. Whole directory: path 'dir/**' with an empty pattern.",
  ],
};

export default function (pi: ExtensionAPI) {
  const hidden = new Set(process.env.PI_SUBAGENT_SESSION ? redundant : [...redundant, ...childOnly]);

  // Not session_start: pi-fff re-activates its tools from its own session_start handler.
  pi.on("before_agent_start", (event) => {
    const active = pi.getActiveTools();
    if (active.some((name) => hidden.has(name))) pi.setActiveTools(active.filter((name) => !hidden.has(name)));

    const options = event.systemPromptOptions as { toolGuidelines?: Record<string, string[]> };
    if (options.toolGuidelines) Object.assign(options.toolGuidelines, rules);
  });
}
