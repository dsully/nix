{
  ai,
  config,
  lib,
  mutableConfig,
  perSystem,
  ...
}: let
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
    ai.lsp;

  # Claude Code expands ${VAR} in MCP headers, while the canonical
  # programs.mcp.servers uses the {env:VAR} form that opencode consumes
  # verbatim. Rewrite the placeholder for any http server with headers and feed
  # it back as programs.claude-code.mcpServers, which the module merges over the
  # generated set per server name. Mirrors the module's own mkMcpServer so the
  # overriding entry stays complete.
  rewriteEnvPlaceholders = lib.replaceStrings ["{env:"] ["\${"];

  claudeMcpServers =
    lib.mapAttrs (
      _: server:
        (lib.removeAttrs server ["disabled"])
        // lib.optionalAttrs (server ? url) {type = "http";}
        // lib.optionalAttrs (server ? command) {type = "stdio";}
        // {
          enabled = !(server.disabled or false);
          headers = lib.mapAttrs (_: rewriteEnvPlaceholders) server.headers;
        }
    )
    (lib.filterAttrs (_: server: server ? headers) config.programs.mcp.servers);

  settings = {
    inherit (ai.models.large) model;

    autoUpdates = false;
    effortLevel = "medium";
    enableAllProjectMcpServers = false;
    enableMcpIntegration = true;
    includeCoAuthoredBy = false;
    # Never commit
    includeGitInstructions = false;

    # Keys below are mkDefault, so a downstream flake can override them with a
    # plain assignment. Any key also present in `ai.enabledPlugins` becomes a
    # plain value via the `//` merge, so overriding those needs lib.mkForce.
    enabledPlugins =
      {
        "code-review@claude-plugins-official" = lib.mkDefault true;
        "code-simplifier@claude-plugins-official" = lib.mkDefault true;
        "commit-commands@claude-plugins-official" = lib.mkDefault true;
        "feature-dev@claude-plugins-official" = lib.mkDefault true;
        "pr-review-toolkit@claude-plugins-official" = lib.mkDefault true;
        "ralph-loop@claude-plugins-official" = lib.mkDefault true;
        "rust-analyzer-lsp@claude-plugins-official" = lib.mkDefault true;
        "superpowers@claude-plugins-official" = lib.mkDefault true;
      }
      // ai.enabledPlugins;

    hooks = lib.mkDefault ai.hooks.claude;

    statusLine = {
      command = lib.getExe perSystem.llm-agents.ccstatusline;
      padding = 0;
      type = "command";
    };

    permissions = ai.permissions.claude.permissions;

    env = {
      CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
      CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
      DISABLE_AUTOUPDATER = "1";
      DISABLE_BUG_COMMAND = "1";
      DISABLE_ERROR_REPORTING = "1";
      DISABLE_TELEMETRY = "1";
      ENABLE_TOOL_SEARCH = "1";
    };

    skipAutoPermissionPrompt = ai.permissions.claude.skipAutoPermissionPrompt;
  };

  settingsPath = "${config.xdg.configHome}/claude/settings.json";
in {
  imports = [
    (mutableConfig.json {
      name = "claude-code";
      target = "claude/settings.json";
      managed =
        config.programs.claude-code.settings
        // {
          "$schema" = "https://json.schemastore.org/claude-code-settings.json";
        };
    })
  ];

  programs.claude-code = {
    enable = true;
    package = perSystem.llm-agents.claude-code;
    enableMcpIntegration = true;

    inherit (ai) agents;
    inherit settings;

    mcpServers = claudeMcpServers;

    configDir = "${config.xdg.configHome}/claude";

    context = ''
      ${builtins.readFile ./AGENTS.md}

      ${builtins.readFile "${perSystem.llm-agents.rtk}/libexec/rtk/hooks/claude/rtk-awareness.md"}
    '';

    lspServers = claudeCodeLsp;
  };

  # The module would symlink settings.json read-only into the /nix/store,
  # which breaks runtime commands like /effort. Disable that and merge the
  # fully-merged settings into a writable file instead.
  home.file."${settingsPath}".enable = lib.mkForce false;
}
