/** The parts of the engine's AgentConfig that shape a pane agent's pi command. */
export interface AgentConfigLike {
  systemPrompt: string;
  promptMode: "replace" | "append";
  model?: string;
  thinking?: string;
  builtinToolNames?: string[];
  extensions: true | string[] | false;
  extSelectors?: string[];
  excludeExtensions?: string[];
  mcpToolPatterns?: string[];
  disallowedTools?: string[];
  skills: true | string[] | false;
}

export interface Launch {
  name: string;
  id: string;
  resultId: string;
  model?: string;
  thinking?: string;
}

/** An extension pi would load, with the lowercased names the engine matches it by. */
export interface Extension {
  path: string;
  names: string[];
}

/** A tool registered in this session; active is false for tools pi leaves off by default. */
export interface Tool {
  name: string;
  path: string;
  active: boolean;
}

/** An agent's extension and tool selection, parsed by the engine's own helpers. */
export interface Scope {
  extensions: true | false | { names: Set<string>; paths: string[]; wildcard: boolean };
  excludeNames: Set<string>;
  extNames: Set<string>;
  narrowing: Map<string, Set<string>>;
  builtinToolNames?: string[];
  mcpToolPatterns?: string[];
  disallowedTools?: string[];
}

/** load: the only extensions to load (with -ne), when filtered; tools: a --tools allowlist, when narrowed. */
export interface Selection {
  load?: string[];
  tools?: string[];
  exclude: string[];
}

const MCP_RESOURCE_TOOLS = ["list_mcp_resources", "list_mcp_resource_templates", "read_mcp_resource"];
const MCP_BRIDGES = new Set(["codemode", "tool_search"]);
const isMcpTool = (name: string) => name.startsWith("mcp__") || MCP_RESOURCE_TOOLS.includes(name);
const matches = (name: string, patterns: string[]) =>
  patterns.some((p) =>
    p.includes("*") ? new RegExp(`^${p.split("*").map((s) => s.replace(/[.+?^${}()|[\]\\]/g, "\\$&")).join(".*")}$`).test(name) : p === name,
  );

/**
 * The pi flags that load and surface what the engine would for an in-process agent (agent-runner.ts's
 * extensionsOverride and installExtensionToolScope). self is this extension, which the child always needs.
 */
export function selection(scope: Scope, extensions: Extension[], tools: Tool[], builtins: string[], self: Extension): Selection {
  const { extensions: spec, excludeNames, extNames, narrowing, builtinToolNames, mcpToolPatterns, disallowedTools } = scope;
  const loadAll = spec === true || (spec !== false && spec.wildcard);
  const kept =
    spec === false
      ? []
      : extensions.filter((e) => !e.names.some((n) => excludeNames.has(n)) && (loadAll || e.names.some((n) => spec.names.has(n))));
  const extra = typeof spec === "object" ? spec.paths.filter((p) => !kept.some((e) => e.path === p)) : [];
  const filtered = !loadAll || excludeNames.size > 0 || !extensions.some((e) => e.path === self.path);
  const load = filtered ? [...new Set([...kept.map((e) => e.path), ...extra, self.path])] : undefined;
  const exclude = [...(disallowedTools ?? [])];

  const optIn = extNames.size > 0;
  const surfaced = (e: Extension) => !optIn || e.names.some((n) => extNames.has(n));
  const mcp = kept.find((e) => e.path === "builtin:mcp");
  // pi's allowlist keeps MCP tools unless an entry names one; the engine drops them with their extension
  if (!mcpToolPatterns && mcp && !surfaced(mcp)) exclude.push("mcp__*", ...MCP_RESOURCE_TOOLS);

  if (!builtinToolNames && !optIn && !mcpToolPatterns && spec !== false) return { load, exclude };
  if (extra.length) throw new Error(`Pane agents can only scope tools of extensions this session has loaded, not ${extra.join(", ")}`);
  const keep = new Set(builtinToolNames ?? builtins);
  for (const tool of tools) {
    const ext = kept.find((e) => e.path === tool.path);
    if (!ext || !surfaced(ext)) continue;
    const only = ext.names.map((n) => narrowing.get(n)).find(Boolean);
    if (only ? only.has(tool.name) : tool.active) keep.add(tool.name);
  }
  if (mcpToolPatterns) {
    for (const name of keep) if (isMcpTool(name) && !matches(name, mcpToolPatterns)) keep.delete(name);
    for (const tool of tools)
      if (kept.some((e) => e.path === tool.path) && (MCP_BRIDGES.has(tool.name) || matches(tool.name, mcpToolPatterns))) keep.add(tool.name);
    for (const pattern of mcpToolPatterns) keep.add(pattern);
  }
  keep.add("ask_parent");
  return { load, tools: [...keep], exclude };
}

const intro = (name: string) =>
  `You are ${name}, a subagent a parent agent started in its own terminal. Your final message is returned to the parent. If you cannot continue without a decision, call ask_parent.`;

/** The command a pane agent runs: an interactive pi that resumes its own session when relaunched. */
export function piCommand(
  a: Launch,
  config: AgentConfigLike,
  sel: Selection,
  skills: { name: string; content: string }[],
  task?: string,
): string[] {
  const args = ["env", `PI_REX_AGENT_ID=${a.id}`, `PI_REX_RESULT_ID=${a.resultId}`, "pi", "--session-id", a.id, "--name", a.name];
  if (a.model) args.push("--model", a.model);
  if (a.thinking) args.push("--thinking", a.thinking);
  const prompt = [config.systemPrompt, ...skills.map((s) => `\n# Preloaded Skill: ${s.name}\n${s.content}`)].join("\n").trim();
  if (config.promptMode === "replace") args.push("--system-prompt", prompt, "--append-system-prompt", intro(a.name));
  else args.push("--append-system-prompt", `${intro(a.name)}\n\n${prompt}`.trim());
  if (sel.load) args.push("--no-extensions", ...sel.load.flatMap((path) => ["-e", path]));
  if (sel.tools) args.push("--tools", sel.tools.join(","));
  if (sel.exclude.length) args.push("--exclude-tools", sel.exclude.join(","));
  // A skills list is preloaded into the prompt above, as the engine does
  if (config.skills !== true) args.push("--no-skills");
  // A leading space keeps pi from treating an @-prefixed task as a file argument
  if (task) args.push("--", task.startsWith("@") ? ` ${task}` : task);
  return args;
}
