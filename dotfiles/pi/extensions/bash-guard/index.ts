import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import { createBashToolDefinition, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { applyInlineFlags } from "./grep-flags.js";
import { interception } from "./interceptor.js";
import { searchesTooBroadly } from "./root-search.js";
import { type Translation, translate } from "./translate.js";

const ROOT_SEARCH_REASON = [
  "Searching from / (find, fd) or all of /nix/store (find, fd, rg, grep) is not allowed.",
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

async function nativeArgs(translation: Translation, cwd: string): Promise<Translation["args"]> {
  if (translation.tailLines === undefined) return translation.args;
  const offset = await tailOffset(resolve(cwd, String(translation.args.path)), translation.tailLines);
  return offset === undefined ? translation.args : { ...translation.args, offset };
}

export default function (pi: ExtensionAPI) {
  const redirect = (command: string): Translation | undefined => {
    const translation = translate(command);
    return translation && pi.getActiveTools().includes(translation.tool) ? translation : undefined;
  };

  pi.on("tool_call", async (event) => {
    if (event.toolName === "grep") return applyInlineFlags(event.input as Record<string, unknown>);
    const command = (event.input as { command?: unknown }).command;
    if (typeof command !== "string") return;
    // Any tool taking a shell command (bash, bg_run) is checked for root searches.
    if (searchesTooBroadly(command)) return { block: true, reason: ROOT_SEARCH_REASON };
    if (event.toolName !== "bash" || redirect(command)) return;
    const reason = interception(command, pi.getActiveTools());
    if (reason) return { block: true, reason };
  });

  // Runs simple lookups through the native tool instead of blocking them, which would cost a model round trip.
  // Pi hands its built-in bash the shellPath and shellCommandPrefix settings; this override does not see them.
  const bash = createBashToolDefinition(process.cwd());
  pi.registerTool({
    ...bash,
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const translation = redirect(params.command);
      if (!translation) return createBashToolDefinition(ctx.cwd).execute(toolCallId, params, signal, onUpdate, ctx);
      const args = await nativeArgs(translation, ctx.cwd);
      const outcome = await ctx.executeTool(translation.tool, args, { signal });
      const note = `[ran as ${translation.tool} ${JSON.stringify(args)}]`;
      const [first, ...rest] = outcome.result.content;
      const content =
        first?.type === "text"
          ? [{ ...first, text: `${note}\n${first.text}` }, ...rest]
          : [{ type: "text" as const, text: note }, ...outcome.result.content];
      return { content, details: undefined, isError: outcome.isError };
    },
  });
}
