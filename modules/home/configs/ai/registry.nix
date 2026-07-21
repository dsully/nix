{
  config,
  inputs,
  lib,
  my,
  pkgs,
  ...
}: let
  # Wrap an MCP stdio server definition so it is launched via mcp-mux, which
  # shares one upstream process across all concurrent MCP client sessions.
  # See https://github.com/thebtf/mcp-mux.
  muxWrap = server:
    server
    // {
      command = lib.getExe my.pkgs.mcp-mux;
      args = [server.command] ++ (server.args or []);
    };

  agentDescription = file: let
    text = builtins.readFile file;
    parts = lib.splitString "description: " text;
  in
    if builtins.length parts >= 2
    then builtins.head (lib.splitString "\n" (builtins.elemAt parts 1))
    else "Specialized development agent";

  lsp = {
    bash = {
      command = lib.getExe pkgs.bash-language-server;
      args = ["start"];
    };
    go = {
      command = lib.getExe pkgs.gopls;
    };
    lua = {
      command = lib.getExe my.pkgs.emmylua-ls;
    };
    nix = {
      command = lib.getExe pkgs.nil;
    };
    rust = {
      command = "rust-analyzer";
      args = [
        "--disable-build-scripts"
      ];
    };
    toml = {
      command = lib.getExe pkgs.tombi;
      args = [
        "lsp"
      ];
    };
    typescript = {
      command = lib.getExe pkgs.typescript-go;
      args = [
        "--lsp"
        "--stdio"
      ];
    };
  };

  mcpServers = {
    codeloupe = {
      command = lib.getExe my.pkgs.codeloupe-mcp;
    };
    git = {
      command = lib.getExe my.pkgs.mcp-server-git-rs;
      args = [
        "--features"
        "inspection,remotes,worktrees,notes"
      ];
      enabled = false;
    };
    git-remote = {
      command = lib.getExe my.pkgs.git-remote-mcp;
      enabled = false;
    };
    indxr = {
      command = lib.getExe my.pkgs.indxr;
      args = ["serve" "." "--all-tools"];
    };
    just = {
      command = lib.getExe my.pkgs.just-mcp;
      enabled = false;
    };
    nixos = {
      command = lib.getExe pkgs.mcp-nixos;
      env = {
        PYTHON_GIL = "1";
      };
      enabled = false;
    };
  };

  models = {
    large = {
      model = "claude-opus-4-8";
      provider = "anthropic";
      max_tokens = 1000000;
      reasoning_effort = "medium";
    };
    medium = {
      model = "claude-sonnet-4-6";
      provider = "anthropic";
      max_tokens = 200000;
      reasoning_effort = "medium";
    };
    small = {
      model = "claude-sonnet-4-5";
      provider = "anthropic";
      max_tokens = 200000;
      reasoning_effort = "low";
    };
  };

  # Curated agents/commands pulled verbatim from pinned marketplace inputs and
  # handed to each tool's native `agents`/`commands` option. The `anthropic-`
  # prefix namespaces claude-plugins-official agents to avoid name clashes.
  agents = {
    anthropic-code-explorer = "${inputs.claude-plugins-official}/plugins/feature-dev/agents/code-explorer.md";
    anthropic-code-reviewer = "${inputs.claude-plugins-official}/plugins/feature-dev/agents/code-reviewer.md";
    anthropic-code-simplifier = "${inputs.claude-plugins-official}/plugins/code-simplifier/agents/code-simplifier.md";
    anthropic-comment-analyzer = "${inputs.claude-plugins-official}/plugins/pr-review-toolkit/agents/comment-analyzer.md";
    debugger = "${inputs.wshobson-agents}/plugins/debugging-toolkit/agents/debugger.md";
  };

  commands = {
    refactor-clean = "${inputs.wshobson-agents}/plugins/code-refactoring/commands/refactor-clean.md";
    tech-debt = "${inputs.wshobson-agents}/plugins/code-refactoring/commands/tech-debt.md";
  };

  descriptions = lib.mapAttrs (_: agentDescription) agents;

  hooks = import ./hooks.nix {inherit config lib pkgs;};

  # Servers that must launch directly, never via mcp-mux. indxr serves a
  # workspace-scoped index from the client's CWD, so a shared mux process would
  # bind it to the wrong workspace for every other session.
  noMuxServers = ["indxr"];

  mcpServersMuxed =
    lib.mapAttrs (
      name: server:
        if builtins.elem name noMuxServers
        then server
        else muxWrap server
    )
    mcpServers;

  permissions = import ./permissions.nix {inherit config lib;};

  # Language-specific rule files. Claude Code loads these natively from its
  # rules/ dir (on-demand via `paths:` frontmatter) and opencode loads them via
  # the `instructions` glob. Tools without a rules mechanism (codex, pi) embed
  # `rulesMarkdown` directly into their context.
  rulesDir = ./rules;

  rulesMarkdown = lib.pipe (builtins.readDir rulesDir) [
    (lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".md" name))
    lib.attrNames
    (map (name: builtins.readFile (rulesDir + "/${name}")))
    (lib.concatStringsSep "\n")
  ];
in {
  inherit
    agentDescription
    agents
    commands
    descriptions
    hooks
    lsp
    models
    muxWrap
    permissions
    rulesDir
    rulesMarkdown
    ;

  mcpServers = mcpServersMuxed;
}
