import { statSync } from "node:fs";
import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import { createBashToolDefinition, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { stripAnsi } from "./ansi.js";
import { applyInlineFlags, negatedGlobReason } from "./grep-flags.js";
import { interception } from "./interceptor.js";
import { runNative } from "./native.js";
import { searchesTooBroadly } from "./root-search.js";
import { type Translation, translate } from "./translate.js";

const ROOT_SEARCH_REASON = [
  "Searching from / or all of /nix/store (find, fd, rg, grep) is not allowed.",
  "For Nix files or derivations: `nix-locate <path>` finds the package that provides a file,",
  "`nix search nixpkgs <name>` finds packages, `nix eval --raw <flake>#<pkg>.outPath` or `nix path-info <installable>`",
  "gives a store path, and `nix-store -qR <path>` lists its closure; search inside that path, never all of /nix/store.",
  "Otherwise use `locate <name>` for system-wide lookups, or `fd <pattern> <dir>` scoped to a specific directory such as the repo or ~.",
].join(" ");

async function tailOffset(file: string, lines: number): Promise<number | undefined> {
  const text = await readFile(file, "utf8").catch(() => undefined);
  if (text === undefined) return undefined;
  const total = text.split("\n").length - (text.endsWith("\n") ? 1 : 0);
  return Math.max(1, total - lines + 1);
}

function isFile(path: string): boolean {
  return statSync(path, { throwIfNoEntry: false })?.isFile() ?? false;
}

async function nativeArgs(translation: Translation, cwd: string): Promise<Translation["args"]> {
  if (translation.tailLines === undefined) return translation.args;
  const offset = await tailOffset(resolve(cwd, String(translation.args.path)), translation.tailLines);
  return offset === undefined ? translation.args : { ...translation.args, offset };
}

type BashResult = Awaited<ReturnType<ReturnType<typeof createBashToolDefinition>["execute"]>>;

// Configs such as ripgrep's `--pretty` force color even without a terminal; the escapes only cost the model tokens.
async function runShell(running: Promise<BashResult>): Promise<BashResult> {
  try {
    const result = await running;
    const content = result.content.map((part) =>
      part.type === "text" ? { ...part, text: stripAnsi(part.text) } : part,
    );
    return { ...result, content };
  } catch (error) {
    if (error instanceof Error) error.message = stripAnsi(error.message);
    throw error;
  }
}

export default function (pi: ExtensionAPI) {
  const redirect = (command: string, cwd: string): Translation | undefined => {
    const translation = translate(command, cwd);
    if (!translation || !pi.getActiveTools().includes(translation.tool)) return undefined;
    const files = translation.paths ?? [String(translation.args.path)];
    if (translation.fileOnly && !files.every((path) => isFile(resolve(cwd, path)))) return undefined;
    return translation;
  };

  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName === "grep") {
      const input = event.input as Record<string, unknown>;
      const reason = negatedGlobReason(input);
      if (reason) return { block: true, reason };
      return applyInlineFlags(input);
    }
    const command = (event.input as { command?: unknown }).command;
    if (typeof command !== "string") return;
    // Any tool taking a shell command (bash, bg_run) is checked for root searches.
    if (searchesTooBroadly(command)) return { block: true, reason: ROOT_SEARCH_REASON };
    if (event.toolName !== "bash" || redirect(command, ctx.cwd)) return;
    const reason = interception(command, pi.getActiveTools());
    if (reason) return { block: true, reason };
  });

  // Runs simple lookups through the native tool instead of blocking them, which would cost a model round trip.
  // Pi hands its built-in bash the shellPath and shellCommandPrefix settings; this override does not see them.
  const bash = createBashToolDefinition(process.cwd());
  pi.registerTool({
    ...bash,
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const translation = redirect(params.command, ctx.cwd);
      if (!translation)
        return runShell(createBashToolDefinition(ctx.cwd).execute(toolCallId, params, signal, onUpdate, ctx));
      const args = await nativeArgs(translation, ctx.cwd);
      const ran = await runNative(translation, args, (tool, toolArgs) => ctx.executeTool(tool, toolArgs, { signal }));
      const scope = translation.paths ? ` on each of ${JSON.stringify(translation.paths)}` : "";
      const note = `[ran as ${translation.tool} ${JSON.stringify(args)}${scope}]`;
      const [first, ...rest] = ran.content;
      const content =
        first?.type === "text"
          ? [{ ...first, text: `${note}\n${first.text}` }, ...rest]
          : [{ type: "text" as const, text: note }, ...ran.content];
      return { content, details: undefined, isError: ran.isError };
    },
  });
}
