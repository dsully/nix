{
  config,
  inputs,
  lib,
  my,
  pkgs,
  ...
}: let
  agentgateway = rec {
    port = 3000;
    baseUrl = "http://localhost:${toString port}";
    mcpHttpUrl = "${baseUrl}/mcp/http";
    mcpSseUrl = "${baseUrl}/mcp/sse";
  };

  agentDescription = file: let
    text = builtins.readFile file;
    parts = lib.splitString "description: " text;
  in
    if builtins.length parts >= 2
    then builtins.head (lib.splitString "\n" (builtins.elemAt parts 1))
    else "Specialized development agent";

  mkAI = sources: let
    sourceList =
      if builtins.isList sources
      then sources
      else [sources];

    normalizeFilter = filter:
      if builtins.isList filter
      then {
        include = filter;
        exclude = [];
      }
      else {
        include = filter.include or [];
        exclude = filter.exclude or [];
      };

    matchesFilter = filter: name: let
      f = normalizeFilter filter;
    in
      (
        f.include
        == []
        || builtins.elem "*" f.include
        || builtins.elem name f.include
      )
      && !(builtins.elem name f.exclude);

    sourcePath = sourceDef:
      sourceDef.source or "${sourceDef.base}/${sourceDef.name}";

    enumerateMdFiles = sourceDef: subdir: filter: let
      source = sourcePath sourceDef;
      prefix = sourceDef.prefix or "";
      dir = "${source}/${subdir}";
      entries =
        if builtins.pathExists dir
        then builtins.readDir dir
        else {};
      mdEntries =
        lib.filterAttrs (
          name: type: let
            key = lib.removeSuffix ".md" name;
          in
            (type == "regular" || type == "symlink")
            && lib.hasSuffix ".md" name
            && matchesFilter filter key
        )
        entries;
    in
      lib.mapAttrs' (
        name: _: let
          key = "${prefix}${lib.removeSuffix ".md" name}";
        in
          lib.nameValuePair key (
            builtins.path {
              path = "${dir}/${name}";
              name = "ai-${subdir}-${key}";
            }
          )
      )
      mdEntries;

    # Missing agents/commands means skip that type; present empty filters mean include all.
    mergeSource = acc: sourceDef: {
      agents =
        acc.agents
        // lib.optionalAttrs (sourceDef ? agents) (
          enumerateMdFiles sourceDef "agents" sourceDef.agents
        );
      commands =
        acc.commands
        // lib.optionalAttrs (sourceDef ? commands) (
          enumerateMdFiles sourceDef "commands" sourceDef.commands
        );
    };
  in
    lib.foldl mergeSource {
      agents = {};
      commands = {};
    }
    sourceList;

  lsp = {
    bash = {
      command = lib.getExe pkgs.bash-language-server;
      args = ["start"];
    };
    helm = {
      command = lib.getExe pkgs.helm-ls;
      args = ["serve" "--stdio"];
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
    ast-grep = {
      command = "${pkgs.uv}/bin/uvx";
      args = ["--from" "git+https://github.com/ast-grep/ast-grep-mcp" "ast-grep-server"];
      env = {
        PYTHON_GIL = "1";
      };
    };
    filesystem = {
      command = lib.getExe my.pkgs.rust-mcp-filesystem;
      args = [config.home.homeDirectory "--allow-write"];
    };
    git = {
      command = lib.getExe my.pkgs.mcp-git-tools;
    };
    git-remote = {
      command = lib.getExe my.pkgs.git-remote-mcp;
    };
    mcp-rust-builder = {
      command = lib.getExe my.pkgs.mcp-rust-builder;
      disabled = true;
    };
    nixos = {
      command = "${pkgs.uv}/bin/uvx";
      args = ["mcp-nixos"];
      env = {
        PYTHON_GIL = "1";
      };
      disabled = true;
    };
    rime = {
      command = lib.getExe my.pkgs.rime;
      args = ["stdio"];
      disabled = true;
    };
    rust-analyzer = {
      command = lib.getExe my.pkgs.mcp-rust-analyzer;
      disabled = true;
    };
    treesitter = {
      command = lib.getExe my.pkgs.treesitter-mcp;
    };
  };

  models = {
    large = {
      model = "claude-opus-4-7";
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

  cpo = "${inputs.claude-plugins-official}/plugins";
  ws = "${inputs.wshobson-agents}/plugins";

  aiSources = [
    {
      base = ws;
      name = "backend-development";
      plugin = "backend-development@claude-code-workflows";
      agents = ["backend-architect" "performance-engineer" "tdd-orchestrator" "test-automator"];
    }
    {
      base = ws;
      name = "code-refactoring";
      commands = ["tech-debt" "refactor-clean"];
    }
    {
      base = ws;
      name = "debugging-toolkit";
      plugin = "debugging-toolkit@claude-code-workflows";
      agents = ["debugger" "dx-optimizer"];
    }
    {
      base = ws;
      name = "python-development";
      plugin = "python-development@claude-code-workflows";
      agents = ["python-pro"];
    }
    {
      base = ws;
      name = "systems-programming";
      plugin = "systems-programming@claude-code-workflows";
      agents = ["rust-pro"];
      commands = ["rust-project"];
    }
    {
      base = cpo;
      name = "code-simplifier";
      prefix = "anthropic-";
      agents = ["code-simplifier"];
    }
    {
      base = cpo;
      name = "feature-dev";
      prefix = "anthropic-";
      agents = ["code-explorer" "code-reviewer"];
    }
    {
      base = cpo;
      name = "pr-review-toolkit";
      prefix = "anthropic-";
      agents = ["comment-analyzer" "silent-failure-hunter" "type-design-analyzer"];
    }
  ];

  aiGenerated = mkAI aiSources;

  inherit (aiGenerated) agents commands;
  descriptions = lib.mapAttrs (_: agentDescription) agents;

  enabledPlugins = lib.genAttrs (
    lib.catAttrs "plugin" aiSources
  ) (_: lib.mkDefault true);
in {
  inherit
    agentgateway
    agentDescription
    agents
    commands
    descriptions
    enabledPlugins
    lsp
    mcpServers
    mkAI
    models
    ;
}
