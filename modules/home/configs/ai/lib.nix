{
  config,
  inputs,
  lib,
  my,
  pkgs,
  ...
}: let
  acp = inputs.astral-claude-plugins;
  cpo = "${inputs.claude-plugins-official}/plugins";
  ws = "${inputs.wshobson-agents}/plugins";

  # Strip YAML frontmatter from a markdown file, returning only the body.
  stripFrontmatter = file: let
    raw = builtins.readFile file;
    parts = lib.splitString "---\n" raw;
  in
    if builtins.length parts >= 3
    then lib.concatStringsSep "" (lib.drop 2 parts)
    else raw;

  # Build an opencode agent markdown string with new frontmatter + original body.
  mkAgent = {
    file,
    description,
    model ? null,
    color ? null,
  }: let
    modelLine = lib.optionalString (model != null) "model: ${model}\n";
    colorLine = lib.optionalString (color != null) "color: ${color}\n";
  in ''
    ---
    description: ${description}
    mode: all
    ${modelLine}${colorLine}---
    ${stripFrontmatter file}'';

  # Build an opencode command markdown string with frontmatter + original body.
  mkCommand = {
    file,
    description,
    agent ? null,
    subtask ? null,
  }: let
    agentLine = lib.optionalString (agent != null) "agent: ${agent}\n";
    subtaskLine = lib.optionalString (subtask != null) "subtask: ${lib.boolToString subtask}\n";
  in ''
    ---
    description: ${description}
    ${agentLine}${subtaskLine}---
    ${stripFrontmatter file}'';

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

  lspExtensions = {
    helm = [".tpl" ".yaml"];
    lua = [".lua"];
    nix = [".nix"];
    rust = [".rs"];
    toml = [".toml"];
    typescript = [".ts" ".tsx" ".js" ".jsx"];
  };

  # Extension-to-language mappings for claude-code's lspServers format.
  lspLanguageIds = {
    bash = {
      ".sh" = "shellscript";
      ".bash" = "shellscript";
    };
    go = {".go" = "go";};
    helm = {
      ".tpl" = "helm";
      ".yaml" = "helm";
    };
    lua = {".lua" = "lua";};
    nix = {".nix" = "nix";};
    rust = {".rs" = "rust";};
    toml = {".toml" = "toml";};
    typescript = {
      ".ts" = "typescript";
      ".tsx" = "typescriptreact";
      ".js" = "javascript";
      ".jsx" = "javascriptreact";
    };
  };

  claudeCodeLsp =
    lib.mapAttrs (
      name: v:
        {
          inherit (v) command;
          extensionToLanguage = lspLanguageIds.${name};
        }
        // lib.optionalAttrs (v ? args) {inherit (v) args;}
    )
    lsp;

  opencodeLsp = lib.mapAttrs (name: v: {
    command = [v.command] ++ (v.args or []);
    extensions = lspExtensions.${name};
  }) (lib.filterAttrs (n: _: lspExtensions ? ${n}) lsp);

  mcpServers = {
    ast-grep = {
      command = "ast-grep-server";
      env = {
        PYTHON_GIL = "1";
      };
    };
    cargo-mcp = {
      command = lib.getExe my.pkgs.cargo-mcp;
      args = ["stdio"];
      disabled = true;
    };
    crates-mcp = {
      command = lib.getExe my.pkgs.crates-mcp;
      disabled = true;
    };
    filesystem = {
      command = lib.getExe my.pkgs.rust-mcp-filesystem;
      args = [config.home.homeDirectory "--allow-write"];
    };
    git = {
      command = lib.getExe my.pkgs.mcp-git-tools;
    };
    git-remote = {
      command = lib.getExe my.pkgs.git-mcp-rs;
    };
    mcp-rust-builder = {
      command = lib.getExe my.pkgs.mcp-rust-builder;
      disabled = true;
    };
    nixos = {
      # command = lib.getExe pkgs.mcp-nixos;
      command = "mcp-nixos";
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

  mcpServersWithType = lib.mapAttrs (_: v: v // {type = "stdio";}) mcpServers;

  models = {
    large = {
      model = "claude-opus-4-6";
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
in {
  inherit
    acp
    claudeCodeLsp
    cpo
    lsp
    lspExtensions
    lspLanguageIds
    mcpServers
    mcpServersWithType
    mkAgent
    mkCommand
    models
    opencodeLsp
    stripFrontmatter
    ws
    ;
}
