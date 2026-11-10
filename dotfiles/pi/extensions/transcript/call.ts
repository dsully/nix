import { isAbsolute, relative } from "node:path";
import { shortCommand } from "../lib/command.js";

type Args = Record<string, unknown> | undefined;

const GLYPHS: ReadonlyMap<string, string> = new Map([
  ["bash", "$"],
  ["read", "●"],
  ["grep", "○"],
  ["find", "○"],
  ["tool_search", "○"],
  ["ls", "≡"],
  ["write", "+"],
  ["insert", "+"],
  ["edit", "±"],
  ["replace", "±"],
  ["replace_match", "±"],
  ["move", "⇄"],
  ["copy", "⧉"],
  ["codemode", "¢"],
  ["web_fetch", "↗"],
  ["web_search", "↗"],
  ["fetch_content", "↗"],
  ["ask_user_question", "?"],
]);

/** Tools whose rows this extension draws itself; every other tool keeps its own renderer. */
export const OWN_TOOLS: ReadonlySet<string> = new Set(
  [...GLYPHS.keys()].filter((name) => name !== "ask_user_question"),
);

export const EDIT_TOOLS: ReadonlySet<string> = new Set(["edit", "replace", "replace_match", "insert"]);

export function glyphOf(toolName: string): string {
  return GLYPHS.get(toolName) ?? (toolName.startsWith("mcp__") ? "◆" : "*");
}

export function shortPath(path: unknown, cwd: string): string {
  const text = typeof path === "string" && path ? path : ".";
  if (!isAbsolute(text)) return text;
  const rel = relative(cwd, text);
  return rel && !rel.startsWith("..") && !isAbsolute(rel) ? rel : text;
}

function str(value: unknown): string | undefined {
  return typeof value === "string" && value ? value : undefined;
}

function firstLine(text: string): string {
  return (
    text
      .split("\n")
      .find((line) => line.trim())
      ?.trim() ?? ""
  );
}

function readRange(args: Args): string {
  const offset = typeof args?.offset === "number" ? args.offset : undefined;
  const limit = typeof args?.limit === "number" ? args.limit : undefined;
  if (offset === undefined) return limit === undefined ? "" : `:1-${limit}`;
  return limit === undefined ? `:${offset}+` : `:${offset}-${offset + limit - 1}`;
}

function inPath(args: Args, cwd: string): string {
  return str(args?.path) ? ` in ${shortPath(args?.path, cwd)}` : "";
}

/** The first code line of a codemode script, skipping its `// @options:` directive. */
export function codemodeHead(code: unknown): string {
  if (typeof code !== "string") return "";
  const lines = code.split("\n").map((line) => line.trim());
  return lines.find((line) => line && !line.startsWith("// @options")) ?? "";
}

/** The text after a row's glyph: what the call acts on, in one line. */
export function callLabel(toolName: string, args: Args, cwd: string): string {
  switch (toolName) {
    case "bash":
      return shortCommand(String(args?.command ?? ""), cwd);
    case "read":
      return `${shortPath(args?.path, cwd)}${readRange(args)}`;
    case "grep":
      return `"${String(args?.pattern ?? "")}"${inPath(args, cwd)}`;
    case "find":
      return `${String(args?.pattern ?? "")}${inPath(args, cwd)}`;
    case "ls":
      return shortPath(args?.path, cwd);
    case "tool_search":
      return `"${String(args?.query ?? "")}"`;
    case "codemode":
      return codemodeHead(args?.code) || "codemode";
    case "web_fetch":
    case "fetch_content":
      return String(args?.url ?? "");
    case "web_search":
      return `"${String(args?.query ?? "")}"`;
    case "move":
    case "copy": {
      const from = args?.path ?? args?.from ?? args?.source;
      const to = args?.to ?? args?.destination ?? args?.target;
      return to === undefined ? shortPath(from, cwd) : `${shortPath(from, cwd)} → ${shortPath(to, cwd)}`;
    }
    default: {
      if (EDIT_TOOLS.has(toolName) || toolName === "write") return shortPath(args?.path, cwd);
      const first = Object.values(args ?? {}).find((value): value is string => typeof value === "string" && !!value);
      const name = toolName.startsWith("mcp__") ? toolName.split("__").slice(1).join("/") : toolName;
      return first ? `${name} ${firstLine(first)}` : name;
    }
  }
}
