import { expect, test } from "bun:test";
import { type AgentConfigLike, type Extension, piCommand, type Scope, selection } from "./command.js";

const ext = (path: string, ...names: string[]): Extension => ({ path, names });
const self = ext("/x/subagents/index.ts", "subagents");
const background = ext("/x/background/index.ts", "background");
const hashline = ext("/x/hashline/index.ts", "index", "pi-hashline-edit-pro-lean");
const mcp = ext("builtin:mcp", "builtin:mcp");
const extensions = [self, background, hashline, mcp];
const tools = [
  { name: "read", path: hashline.path, active: true },
  { name: "replace", path: hashline.path, active: true },
  { name: "bg_run", path: background.path, active: true },
  { name: "bg_hidden", path: background.path, active: false },
  { name: "mcp__s__t", path: mcp.path, active: true },
];
const builtins = ["read", "bash", "edit", "write"];
const all: Scope = { extensions: true, excludeNames: new Set(), extNames: new Set(), narrowing: new Map() };
const pick = (scope: Partial<Scope>) => selection({ ...all, ...scope }, extensions, tools, builtins, self);

test("an agent with every extension and tool passes no selection flags", () => {
  expect(pick({})).toEqual({ load: undefined, exclude: [] });
});

test("disallowed tools are excluded, MCP ones included", () => {
  expect(pick({ disallowedTools: ["bg_run", "mcp__s__t"] }).exclude).toEqual(["bg_run", "mcp__s__t"]);
});

test("an extension list or exclusion loads only the kept extensions, and always this one", () => {
  const spec = { names: new Set(["pi-hashline-edit-pro-lean"]), paths: ["/y/extra.ts"], wildcard: false };
  expect(pick({ extensions: spec }).load).toEqual([hashline.path, "/y/extra.ts", self.path]);
  expect(pick({ excludeNames: new Set(["background"]) }).load).toEqual([self.path, hashline.path, mcp.path]);
  expect(pick({ extensions: false })).toEqual({ load: [self.path], tools: [...builtins, "ask_parent"], exclude: [] });
});

test("this extension is loaded explicitly when pi would not discover it", () => {
  expect(selection(all, [background], tools, builtins, self).load).toEqual([background.path, self.path]);
});

test("limited builtins keep the default-on tools of loaded extensions", () => {
  expect(pick({ builtinToolNames: ["read"] }).tools).toEqual(["read", "replace", "bg_run", "mcp__s__t", "ask_parent"]);
});

test("ext: selectors opt extensions in, narrow them to named tools, and drop unselected MCP", () => {
  const narrowing = new Map([["background", new Set(["bg_hidden"])]]);
  const sel = pick({ extNames: new Set(["background"]), narrowing });
  expect(sel.tools).toEqual([...builtins, "bg_hidden", "ask_parent"]);
  expect(sel.exclude).toContain("mcp__*");
});

test("mcp patterns keep only matching MCP tools", () => {
  const sel = pick({ mcpToolPatterns: ["mcp__other__*"] });
  expect(sel.tools).not.toContain("mcp__s__t");
  expect(sel.tools).toContain("mcp__other__*");
});

test("scoping tools of an extension this session has not loaded fails instead of dropping them", () => {
  const spec = { names: new Set<string>(), paths: ["/y/extra.ts"], wildcard: false };
  expect(() => pick({ extensions: spec, builtinToolNames: ["read"] })).toThrow("/y/extra.ts");
});

test("piCommand loads, scopes, preloads skills, and guards an @-prefixed task", () => {
  const base: AgentConfigLike = { systemPrompt: "Be brief.", promptMode: "append", extensions: true, skills: ["nix"] };
  const a = { name: "explore-1", id: "sid", resultId: "rid", model: "anthropic/x" };
  const sel = { load: ["/a.ts"], tools: ["read"], exclude: ["bash"] };
  const args = piCommand(a, base, sel, [{ name: "nix", content: "Use alejandra." }], "@src look");
  expect(args.slice(0, 4)).toEqual(["env", "PI_REX_AGENT_ID=sid", "PI_REX_RESULT_ID=rid", "pi"]);
  expect(args[args.indexOf("--append-system-prompt") + 1]).toEndWith(
    "Be brief.\n\n# Preloaded Skill: nix\nUse alejandra.",
  );
  for (const flag of ["--no-extensions", "-e", "--tools", "--exclude-tools", "--no-skills"])
    expect(args).toContain(flag);
  expect(args.at(-1)).toBe(" @src look");
  const replace = piCommand(a, { ...base, promptMode: "replace", skills: true }, { exclude: [] }, []);
  expect(replace[replace.indexOf("--system-prompt") + 1]).toBe("Be brief.");
  expect(replace).not.toContain("--no-skills");
  expect(replace).not.toContain("--");
});
