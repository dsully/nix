// Pane agents adapted from https://github.com/maxpaulus43/pi-rex-agents (MIT): a subagent that is an interactive pi in a Rex pane.
import { randomUUID } from "node:crypto";
import { existsSync, mkdirSync, readFileSync, realpathSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { StringEnum } from "@earendil-works/pi-ai";
import {
  DefaultPackageManager,
  type ExtensionAPI,
  type ExtensionContext,
  getAgentDir,
  SettingsManager,
} from "@earendil-works/pi-coding-agent";
import { type TSchema, Type } from "typebox";
import { blockExists, here, openPane, type Placement, sendToBlock, shellLayout, watchEvents } from "../lib/rex.js";
import { type AgentConfigLike, piCommand, type Scope, selection } from "./command.js";

/** The engine exports pane agents read definitions and their resource scoping from. */
export interface Engine {
  BUILTIN_TOOL_NAMES: string[];
  resolveType(name: string): string | undefined;
  getAgentConfig(name: string): AgentConfigLike | undefined;
  getAvailableTypes(): string[];
  extensionCanonicalNames(path: string): string[];
  parseExtSelectors(entries: string[]): { extNames: Set<string>; narrowing: Map<string, Set<string>> };
  parseExtensionsSpec(entries: string[], cwd: string): { names: Set<string>; paths: string[]; wildcard: boolean };
  preloadSkills(names: string[], cwd: string): { name: string; content: string }[];
}

// The extensions pi's CLI adds itself, as the engine forwards them to in-process agents
const BUILTIN_EXTENSIONS = ["codemode", "tool-search", "mcp"];

export interface RexAgents {
  paneParameter: TSchema;
  guideline: string;
  /** Handles run with pane, and steer or result for a pane agent; undefined leaves the operation to the engine. */
  route(op: string, params: Record<string, unknown>, ctx: ExtensionContext): Promise<ToolResult | undefined>;
}

type ToolResult = { content: { type: "text"; text: string }[]; details: { rexAgent: string } };

interface Agent {
  name: string;
  // pi session id, kept across relaunches so a settled agent resumes its conversation
  id: string;
  // names the file the child writes its final message to; new per launch, so a resumed agent never returns a stale one
  resultId: string;
  type: string;
  model?: string;
  thinking?: string;
  cwd: string;
  placement: Placement;
  session: string;
  block: string;
  alive?: boolean;
  state?: string;
  asked?: string;
}

const ENTRY = "rex-agent";
const MAX_RESULT = 50_000;
const resultPath = (resultId: string) => join(getAgentDir(), "rex-agents", `${resultId}.md`);

const lastAssistantText = (messages: any[]) => {
  const m = [...messages].reverse().find((x) => x.role === "assistant");
  if (!m) return "";
  if (m.stopReason === "error") return `Error: ${m.errorMessage ?? "unknown"}`;
  return (m.content ?? [])
    .filter((c: any) => c.type === "text")
    .map((c: any) => c.text)
    .join("\n");
};

export function rexAgents(pi: ExtensionAPI, engine: Engine): RexAgents | undefined {
  const agents = new Map<string, Agent>();

  const childId = process.env.PI_REX_AGENT_ID;
  const resultId = process.env.PI_REX_RESULT_ID;
  if (childId && resultId) {
    pi.on("agent_end", (event) => {
      const file = resultPath(resultId);
      mkdirSync(dirname(file), { recursive: true });
      writeFileSync(file, lastAssistantText(event.messages));
    });
    // Closing the pane hands the result to the parent; not after an abort, or while this agent's own pane agents run
    pi.on("agent_settled", (event, ctx) => {
      if (!event.aborted && ![...agents.values()].some((a) => a.alive) && !ctx.hasPendingMessages()) ctx.shutdown();
    });
    pi.registerTool({
      name: "ask_parent",
      label: "Ask Parent",
      description:
        "Ask the parent agent one short question and wait for its answer. Use only when you cannot proceed without a decision.",
      promptSnippet: "Ask the parent agent a short question and wait for the answer",
      parameters: Type.Object({ question: Type.String({ description: "One short, self-contained question" }) }),
      async execute(_id, { question }, _signal, _onUpdate, ctx) {
        // The dialog makes pi report OSC 7501 blocked with this title, which the parent sees as a program_status_changed event
        const answer = await ctx.ui.editor(`Question for parent: ${question.replace(/\s+/g, " ").slice(0, 600)}`, "");
        const text = answer?.trim() ? `Parent answered: ${answer.trim()}` : "No answer. Use your best judgment.";
        return { content: [{ type: "text", text }], details: {} };
      },
    });
  }

  const parent = here();
  if (!parent) return undefined;

  let ui: ExtensionContext["ui"] | undefined;
  const watchers = new Map<string, () => void>();
  // Result files to delete once the message carrying them is in the session log
  const pendingCleanup = new Set<string>();

  const showStatus = () => {
    const live = [...agents.values()].filter((a) => a.alive);
    ui?.setWidget(
      ENTRY,
      live.length ? [`Rex agents: ${live.map((a) => `${a.name}:${a.state ?? "?"}`).join(" ")}`] : undefined,
    );
  };

  const tell = (content: string, cleanup?: string) =>
    pi.sendMessage(
      { customType: ENTRY, content, display: true, details: cleanup },
      { triggerTurn: true, deliverAs: "steer" },
    );

  const readResult = (a: Agent) => {
    const file = resultPath(a.resultId);
    return existsSync(file) ? readFileSync(file, "utf8") : "";
  };

  const onClosed = (a: Agent) => {
    a.alive = false;
    a.state = "closed";
    showStatus();
    const result = readResult(a);
    if (result.length <= MAX_RESULT) pendingCleanup.add(a.resultId);
    tell(
      `Agent ${a.name} settled and closed its pane. Result:\n\n${result.slice(0, MAX_RESULT) || "(no result)"}`,
      a.resultId,
    );
  };

  const onEvent = (ev: any) => {
    const a = [...agents.values()].find((x) => x.alive && x.block === ev?.payload?.block_id);
    if (!a) return;
    if (ev.type === "block_closed") return onClosed(a);
    if (ev.type !== "block_event" || ev.payload.name !== "program_status_changed") return;
    const { id, record } = ev.payload.payload ?? {};
    if (id !== "" || !record?.state) return;
    a.state = record.state;
    showStatus();
    if (record.state !== "blocked") return void (a.asked = undefined);
    const msg = record.msg ?? "";
    if (a.asked === msg) return;
    a.asked = msg;
    tell(
      `Agent ${a.name} is waiting for input (${record.kind ?? "question"}): ${msg}\nAnswer with subagent op=steer, agent_id "${a.name}"; the text is typed into its prompt and submitted.`,
    );
  };

  const watch = (session: string) => {
    if (!watchers.has(session)) watchers.set(session, watchEvents(session, onEvent));
  };

  const cleanupResults = (_event: unknown, ctx: ExtensionContext) => {
    if (!pendingCleanup.size) return;
    for (const entry of ctx.sessionManager.getEntries()) {
      if (entry.type !== "custom_message" || entry.customType !== ENTRY || typeof entry.details !== "string") continue;
      if (pendingCleanup.delete(entry.details)) rmSync(resultPath(entry.details), { force: true });
    }
  };
  pi.on("turn_end", cleanupResults);
  pi.on("agent_settled", cleanupResults);

  // The engine's own discovery and parsing, so a pane agent loads and surfaces what an in-process one would
  const scoped = async (config: AgentConfigLike, ctx: ExtensionContext) => {
    const agentDir = getAgentDir();
    const settingsManager = SettingsManager.create(ctx.cwd, agentDir, { projectTrusted: ctx.isProjectTrusted() });
    const resolved = await new DefaultPackageManager({ cwd: ctx.cwd, agentDir, settingsManager }).resolve();
    const real = (path: string) => (existsSync(path) ? realpathSync(path) : path);
    const named = (path: string) => ({ path, names: engine.extensionCanonicalNames(path) });
    const disabled = process.argv.some((a) => a === "--no-extensions" || a === "-ne")
      ? BUILTIN_EXTENSIONS
      : process.argv.includes("--no-mcp")
        ? ["mcp"]
        : [];
    const extensions = [
      ...resolved.extensions.filter((e) => e.enabled).map((e) => named(real(e.path))),
      ...BUILTIN_EXTENSIONS.filter((n) => !disabled.includes(n)).map((n) => named(`builtin:${n}`)),
    ];
    const tools = pi
      .getAllTools()
      .filter((t) => t.exposure === "direct" || t.exposure === "model-only")
      .map((t) => ({ name: t.name, path: real(t.sourceInfo.path), active: pi.getActiveTools().includes(t.name) }));
    const own = pi.getAllTools().find((t) => t.name === "subagent")?.sourceInfo.path;
    if (!own) throw new Error("Could not find the subagents extension's own path");
    const { extNames, narrowing } = engine.parseExtSelectors(config.extSelectors ?? []);
    const scope: Scope = {
      extensions: Array.isArray(config.extensions) ? engine.parseExtensionsSpec(config.extensions, ctx.cwd) : config.extensions,
      excludeNames: new Set((config.excludeExtensions ?? []).map((n) => n.toLowerCase())),
      extNames,
      narrowing,
      builtinToolNames: config.builtinToolNames,
      mcpToolPatterns: config.mcpToolPatterns,
      disallowedTools: config.disallowedTools,
    };
    return {
      sel: selection(scope, extensions, tools, engine.BUILTIN_TOOL_NAMES, named(real(own))),
      skills: Array.isArray(config.skills) ? engine.preloadSkills(config.skills, ctx.cwd) : [],
    };
  };

  const launch = async (a: Agent, task: string | undefined, ctx: ExtensionContext) => {
    const config = engine.getAgentConfig(a.type);
    if (!config) throw new Error(`Agent type ${a.type} is no longer defined`);
    const { sel, skills } = await scoped(config, ctx);
    a.resultId = randomUUID();
    watch(a.session);
    const live = [...agents.values()].filter((x) => x !== a && x.alive && x.placement === a.placement);
    // The first split goes beside the parent; later ones stack under the newest live one
    const sibling = a.placement === "split" ? live.at(-1) : undefined;
    const k = live.length % 5;
    const pane = await openPane(
      a.session,
      sibling?.block ?? parent.block,
      a.placement,
      shellLayout(a.name, piCommand(a, config, sel, skills, task), a.cwd, false),
      {
        label: a.name,
        direction: sibling ? "vertical" : "horizontal",
        bounds: [0.05 + 0.04 * k, 0.05 + 0.04 * k, 0.6, 0.7],
      },
    );
    Object.assign(a, { block: pane.block_id, alive: true, state: "starting", asked: undefined });
    const { alive: _alive, state: _state, asked: _asked, ...saved } = a;
    pi.appendEntry(ENTRY, saved);
    showStatus();
  };

  const reply = (a: Agent, text: string): ToolResult => ({
    content: [{ type: "text", text }],
    details: { rexAgent: a.name },
  });

  const spawn = async (params: Record<string, unknown>, ctx: ExtensionContext) => {
    const requested = typeof params.subagent_type === "string" ? params.subagent_type : "general-purpose";
    const type = engine.resolveType(requested);
    const config = type ? engine.getAgentConfig(type) : undefined;
    if (!type || !config)
      throw new Error(`Unknown subagent_type "${requested}". Available: ${engine.getAvailableTypes().join(", ")}`);
    const task = typeof params.prompt === "string" ? params.prompt.trim() : "";
    if (!task) throw new Error("op=run needs prompt");
    let name = typeof params.name === "string" && params.name.trim() ? params.name.trim() : undefined;
    if (!name) {
      let n = 1;
      while (agents.has(`${type.toLowerCase()}-${n}`)) n++;
      name = `${type.toLowerCase()}-${n}`;
    }
    if (agents.has(name)) throw new Error(`agent_id "${name}" is taken`);
    const pinned =
      typeof params.model === "string"
        ? params.model
        : config.model && config.model !== "inherit"
          ? config.model
          : undefined;
    const inherit = !pinned && ctx.model;
    const a: Agent = {
      name,
      id: randomUUID(),
      resultId: "",
      type,
      model: pinned ?? (inherit ? `${ctx.model!.provider}/${ctx.model!.id}` : undefined),
      thinking: config.thinking ?? (inherit ? pi.getThinkingLevel() : undefined),
      cwd: ctx.cwd,
      placement: params.pane as Placement,
      session: parent.session,
      block: "",
    };
    agents.set(name, a);
    try {
      await launch(a, task, ctx);
    } catch (error) {
      agents.delete(name);
      throw error;
    }
    const where =
      a.placement === "float" ? "a minimized Rex float" : a.placement === "split" ? "a Rex split" : "a new Rex tab";
    return reply(
      a,
      `Started ${name} (${type}) in ${where}; agent_id "${name}". Its result and any question arrive as messages; op=steer answers or follows up.`,
    );
  };

  const steer = async (a: Agent, message: string, ctx: ExtensionContext) => {
    if (a.alive) {
      try {
        await sendToBlock(a.session, a.block, message, "enter");
        a.asked = undefined;
        return reply(a, `Sent to ${a.name}.`);
      } catch {
        a.alive = false;
      }
    }
    await launch(a, message, ctx);
    return reply(a, `Resumed ${a.name} with the message.`);
  };

  pi.on("session_start", (_event, ctx) => {
    ui = ctx.ui;
    for (const e of ctx.sessionManager.getEntries() as any[]) {
      if (e.type !== "custom" || e.customType !== ENTRY) continue;
      const a: Agent = { ...e.data, alive: false };
      agents.set(a.name, a);
      // A pane that still exists, as after /reload, is still running
      void blockExists(a.session, a.block).then((exists) => {
        if (!exists || agents.get(a.name) !== a) return;
        Object.assign(a, { alive: true, state: "unknown" });
        watch(a.session);
        showStatus();
      });
    }
  });
  pi.on("session_shutdown", () => {
    for (const stop of watchers.values()) stop();
    watchers.clear();
  });

  return {
    paneParameter: Type.Optional(
      StringEnum(["split", "float", "window"] as const, {
        description:
          "run: start the agent as an interactive pi in a Rex pane (float starts minimized) the user can watch and type into, instead of in-process",
      }),
    ),
    guideline:
      'subagent: a run with pane gets the agent\'s name as agent_id; its final message and questions arrive as messages, and steer types into its pane or resumes it. Optional input "name" picks the name.',
    async route(op, params, ctx) {
      if (op === "run") return params.pane ? spawn(params, ctx) : undefined;
      const a = typeof params.agent_id === "string" ? agents.get(params.agent_id) : undefined;
      if (!a) return undefined;
      if (op === "steer") {
        if (typeof params.message !== "string" || !params.message.trim()) throw new Error("op=steer needs message");
        return steer(a, params.message, ctx);
      }
      if (op === "result") {
        const result = readResult(a);
        return reply(
          a,
          `${a.name} (${a.type}): ${a.alive ? (a.state ?? "running") : "settled"}${result ? `\nLatest final message:\n${result.slice(0, MAX_RESULT)}` : ""}`,
        );
      }
      return undefined;
    },
  };
}
