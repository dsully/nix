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
  #
  # A server may set `stateless = true` when its behavior does not depend on the
  # client's working directory (e.g. a network/API server). That drops cwd from
  # mcp-mux's server-identity hash (`--stateless`), so one upstream is shared
  # globally instead of one per project directory. The marker is stripped here;
  # it is not a valid key on the typed `programs.mcp.servers` option.
  # Priority-wrapped values (lib.mkForce et al.) are unwrapped, wrapped, and
  # re-wrapped, so a consumer can mkForce a server over an upstream definition.
  muxWrap = server: let
    stateless = server.stateless or false;
    base = removeAttrs server ["stateless"];
  in
    if server._type or null == "override"
    then server // {content = muxWrap server.content;}
    else
      base
      // {
        command = lib.getExe my.pkgs.mcp-mux;
        args = lib.optional stateless "-stateless" ++ [base.command] ++ (base.args or []);
        # A shim respawns the daemon from this pointer instead of its own binary, so
        # shims from an older generation cannot resurrect a stale daemon version.
        env = (base.env or {}) // {MCPMUX_ACTIVE_ENGINE_FILE = muxEngineFile;};
      };

  muxEngineFile = "${config.xdg.stateHome}/mcp-mux/active-engine";

  agentDescription = file: let
    text = builtins.readFile file;
    parts = lib.splitString "description: " text;
  in
    if builtins.length parts >= 2
    then builtins.head (lib.splitString "\n" (builtins.elemAt parts 1))
    else "Specialized development agent";

  # Rewrite a Claude-format agent file, dropping the frontmatter keys named in
  # `dropKeys` (lowercase, with the trailing colon). Files with no frontmatter
  # block pass through unchanged.
  sanitizeAgentWith = dropKeys: file: let
    text = builtins.readFile file;
    parts = lib.splitString "---\n" text;
    drop = line: let
      l = lib.toLower line;
    in
      lib.any (k: lib.hasPrefix k l) dropKeys;
  in
    if lib.hasPrefix "---\n" text && builtins.length parts >= 3
    then let
      fm = lib.filter (l: l != "" && !drop l) (lib.splitString "\n" (builtins.elemAt parts 1));
      body = lib.trim (lib.concatStringsSep "---\n" (lib.drop 2 parts));
    in "---\n${lib.concatStringsSep "\n" fm}\n---\n${body}\n"
    else text;

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
      command = lib.getExe pkgs.typescript;
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
        enabled = false;
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
      apple-apps = {
        command = lib.getExe pkgs.bun;
        args = ["/Applications/Apple MCP.app/Contents/Resources/dist/mcp/index.js"];
        enabled = false;
        stateless = true;
      };
      safari-mcp = {
        command = "/usr/bin/safaridriver";
        args = ["--mcp"];
        enabled = false;
        stateless = true;
      };
    };

  models = {
    large-high = {
      model = "claude-opus-5-5";
      provider = "anthropic";
      max_tokens = 1000000;
      reasoning_effort = "high";
    };
    large = {
      model = "claude-opus-5-5";
      provider = "anthropic";
      max_tokens = 1000000;
      reasoning_effort = "medium";
    };
    medium = {
      model = "claude-sonnet-5-5";
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
    codebase-pattern-finder = "${inputs.softaworks}/agents/codebase-pattern-finder.md";
    code-explorer = "${inputs.claude-plugins-official}/plugins/feature-dev/agents/code-explorer.md";
    code-reviewer = "${inputs.claude-plugins-official}/plugins/feature-dev/agents/code-reviewer.md";
    code-simplifier = "${inputs.claude-plugins-official}/plugins/code-simplifier/agents/code-simplifier.md";
    comment-analyzer = "${inputs.claude-plugins-official}/plugins/pr-review-toolkit/agents/comment-analyzer.md";
    debugger = "${inputs.wshobson-agents}/plugins/debugging-toolkit/agents/debugger.md";
  };

  commandSources = {
    refactor-clean = "${inputs.wshobson-agents}/plugins/code-refactoring/commands/refactor-clean.md";
    tech-debt = "${inputs.wshobson-agents}/plugins/code-refactoring/commands/tech-debt.md";
  };

  agents = lib.mapAttrs (_: builtins.readFile) agentSources;
  commands = lib.mapAttrs (_: builtins.readFile) commandSources;
  descriptions = lib.mapAttrs (_: agentDescription) agentSources;

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

  # pi and claude-code each install context-mode; pin the one
  # version here so they cannot drift apart.
  contextModeVersion = "1.0.169";

  permissions = import ./permissions.nix {inherit config lib;};

  # Output styles, in Claude Code's format (frontmatter + system-prompt body).
  # The attribute name is the style id: Claude Code writes it to
  # `output-styles/<id>.md` and matches `settings.outputStyle` against it.
  #
  # Each file's frontmatter `name` is kept equal to its id so both
  # tools agree on one identifier.
  outputStyles = {
    asd-ste-100 = ./output-styles/asd-ste-100.md;
  };

  defaultOutputStyle = "asd-ste-100";

  # Language-specific rule files. Claude Code loads these natively from its
  # rules/ dir (on-demand via `paths:` frontmatter).
  #
  # Tools without a rules mechanism (codex, pi) embed `rulesMarkdown` directly into their context.
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
    contextModeVersion
    defaultOutputStyle
    descriptions
    hooks
    lsp
    models
    muxEngineFile
    muxWrap
    outputStyles
    permissions
    sanitizeAgentWith
    rulesDir
    rulesMarkdown
    ;

  mcpServers = mcpServersMuxed;
}
