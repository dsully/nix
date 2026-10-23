/**
 * Deactivates tools whose job another declared tool already does, or that cannot work in this session, to save prompt tokens,
 * drops the system prompt's tool list (it repeats the tool declarations), and condenses rules that repeat tool descriptions.
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

// Replaces each tool's rules; memory rules repeat the memory reminder message.
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
  recall: [
    "Use recall on a specific compacted-memory id when the exact wording, paths, commands, or rationale behind it matter.",
  ],
  memory_store: [],
  memory_search: [],
  memory_delete: [],
  memory_list: [],
  global_memory_list: [],
};

export default function (pi: ExtensionAPI) {
  const hidden = new Set(process.env.PI_SUBAGENT_SESSION ? redundant : [...redundant, ...childOnly]);

  // Not session_start: pi-fff re-activates its tools from its own session_start handler.
  pi.on("before_agent_start", (event) => {
    const active = pi.getActiveTools();
    if (active.some((name) => hidden.has(name))) pi.setActiveTools(active.filter((name) => !hidden.has(name)));

    const options = event.systemPromptOptions as {
      toolSnippets?: Record<string, string>;
      toolGuidelines?: Record<string, string[]>;
    };
    if (options.toolSnippets) for (const name of Object.keys(options.toolSnippets)) delete options.toolSnippets[name];
    if (options.toolGuidelines) Object.assign(options.toolGuidelines, rules);
  });
}
