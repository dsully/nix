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

  mcpServers =
    {
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
        args = ["serve" "."];
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
    }
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      safari-mcp = {
        command = "/usr/bin/safaridriver";
        args = ["--mcp"];
        enabled = false;
      };
    };

  models = {
    large = {
      model = "claude-opus-5";
      provider = "anthropic";
      max_tokens = 1000000;
      reasoning_effort = "medium";
    };
    medium = {
      model = "claude-sonnet-5";
      provider = "anthropic";
      max_tokens = 200000;
      reasoning_effort = "medium";
    };
    small = {
      model = "claude-haiku-4-5-20251001";
      provider = "anthropic";
      max_tokens = 200000;
      reasoning_effort = "low";
    };
  };

  # Curated agents/commands pulled verbatim from pinned marketplace inputs and
  # handed to each tool's native `agents`/`commands` option. The `anthropic-`
  # prefix namespaces claude-plugins-official agents to avoid name clashes.
  #
  # These are *sources*: interpolating a flake input yields a plain string, and
  # the `agents`/`commands` options are `either lines path` — a string is taken
  # as file content, so passing the interpolation directly writes the store path
  # into the file instead of the agent. Read them (below) to get real content.
  agentSources = {
    anthropic-code-explorer = "${inputs.claude-plugins-official}/plugins/feature-dev/agents/code-explorer.md";
    anthropic-code-reviewer = "${inputs.claude-plugins-official}/plugins/feature-dev/agents/code-reviewer.md";
    anthropic-code-simplifier = "${inputs.claude-plugins-official}/plugins/code-simplifier/agents/code-simplifier.md";
    anthropic-comment-analyzer = "${inputs.claude-plugins-official}/plugins/pr-review-toolkit/agents/comment-analyzer.md";
    debugger = "${inputs.wshobson-agents}/plugins/debugging-toolkit/agents/debugger.md";

    softaworks-ascii-ui-mockup-generator = "${inputs.softaworks}/agents/ascii-ui-mockup-generator.md";
    softaworks-codebase-pattern-finder = "${inputs.softaworks}/agents/codebase-pattern-finder.md";
    softaworks-communication-excellence-coach = "${inputs.softaworks}/agents/communication-excellence-coach.md";
    softaworks-general-purpose = "${inputs.softaworks}/agents/general-purpose.md";
    softaworks-mermaid-diagram-specialist = "${inputs.softaworks}/agents/mermaid-diagram-specialist.md";
    softaworks-ui-ux-designer = "${inputs.softaworks}/agents/ui-ux-designer.md";
  };

  commandSources = {
    refactor-clean = "${inputs.wshobson-agents}/plugins/code-refactoring/commands/refactor-clean.md";
    tech-debt = "${inputs.wshobson-agents}/plugins/code-refactoring/commands/tech-debt.md";
  };

  agents = lib.mapAttrs (_: builtins.readFile) agentSources;
  commands = lib.mapAttrs (_: builtins.readFile) commandSources;
  descriptions = lib.mapAttrs (_: agentDescription) agentSources;

  hooks = import ./hooks.nix {inherit config lib my pkgs;};

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

  # Output styles, in Claude Code's format (frontmatter + system-prompt body).
  # The attribute name is the style id: Claude Code writes it to
  # `output-styles/<id>.md` and matches `settings.outputStyle` against it, and
  # opencode-output-styles derives its `/output-style <id>` id from the same
  # filename. Each file's frontmatter `name` is kept equal to its id so both
  # tools agree on one identifier.
  outputStyles = {
    asd-ste-100 = ./output-styles/asd-ste-100.md;
  };

  # The style every tool starts in. Claude Code applies it declaratively via
  # `settings.outputStyle`; opencode has no declarative equivalent, so
  # opencode.nix loads the same file through `instructions`.
  defaultOutputStyle = "asd-ste-100";

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
    defaultOutputStyle
    descriptions
    hooks
    lsp
    models
    muxWrap
    outputStyles
    permissions
    rulesDir
    rulesMarkdown
    ;

  mcpServers = mcpServersMuxed;
}
