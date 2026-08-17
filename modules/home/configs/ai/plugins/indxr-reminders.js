// Equivalent of the Claude Code PreToolUse indxr hooks, adapted to opencode.
//
// opencode pre-tool hooks have no soft-reminder channel: a `throw` in
// `tool.execute.before` is a hard block. So this plugin splits the two hooks:
//
//   - read  -> soft nudge. The read runs; a reminder is appended to its output
//              (via `tool.execute.after`) so the model sees it next turn. Gated
//              to source files only, so reading configs/docs (Cargo.toml, *.md,
//              *.json) stays quiet.
//   - bash  -> hard block when the command runs `git diff`, redirecting the
//              model to the indxr `get_diff_summary` MCP tool.

const READ_REMINDER = [
  "",
  "---",
  "REMINDER: Before reading full source files, prefer indxr MCP tools to cut token use:",
  "- summarize(path): understand a file without reading it (~300 tokens vs ~3000+)",
  "- find(query): find functions/types by name, concept, or signature",
  "- read(path, symbol): read only the exact symbol you need (~100 tokens vs full file)",
  "Use the Read tool only to EDIT a file, when you need exact formatting, or for",
  "non-source files (e.g. CLAUDE.md, Cargo.toml).",
].join("\n");

const GIT_DIFF_BLOCK =
  "Use the indxr get_diff_summary MCP tool instead of `git diff`. " +
  "It shows structural changes (added/removed/modified declarations) at " +
  "~200-500 tokens vs thousands for a raw diff. " +
  'Example: get_diff_summary(since_ref: "main").';

const GIT_DIFF_RE = /git\s+diff/;

// Extensions indxr can navigate. Configs/docs are excluded so they never nudge.
const SOURCE_EXTENSIONS = new Set([
  "c", "cc", "cpp", "cxx", "h", "hpp", "hxx",
  "go", "java", "js", "jsx", "kt", "kts", "lua",
  "mjs", "cjs", "nix", "py", "pyi", "rb", "rs",
  "swift", "ts", "tsx",
]);

const isSourceFile = (filePath) => {
  const dot = filePath.lastIndexOf(".");
  if (dot < 0) return false;
  return SOURCE_EXTENSIONS.has(filePath.slice(dot + 1).toLowerCase());
};

export const IndxrReminders = async () => {
  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool === "bash") {
        const command = output.args?.command ?? "";
        if (GIT_DIFF_RE.test(command)) {
          throw new Error(GIT_DIFF_BLOCK);
        }
      }
    },

    "tool.execute.after": async (input, output) => {
      if (input.tool === "read" && isSourceFile(input.args?.filePath ?? "")) {
        output.output = `${output.output}${READ_REMINDER}`;
      }
    },
  };
};
