{
  ai,
  config,
  inputs,
  lib,
  perSystem,
  ...
}: let
  lspLanguageIds = {
    bash = {
      ".sh" = "shellscript";
      ".bash" = "shellscript";
    };
    go = {".go" = "go";};
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
  # verbatim. Rewrite the placeholder for any remote server with headers and
  # feed it back as programs.claude-code.mcpServers, which the module merges
  # over the generated set per server name. Run it through the same
  # lib.hm.mcp.transformMcpServer the module uses so the override is normalized
  # identically (type added, the unsupported `enabled` field stripped, nulls
  # and empty defaults filtered out).
  rewriteEnvPlaceholders = lib.replaceStrings ["{env:"] ["\${"];

  claudeMcpServers =
    lib.mapAttrs (
      _: server:
        lib.hm.mcp.transformMcpServer {
          inherit server;
          exclude = ["enabled"];
          extraTransforms = [
            lib.hm.mcp.addType
            (s: s // {headers = lib.mapAttrs (_: rewriteEnvPlaceholders) s.headers;})
          ];
        }
    )
    (lib.filterAttrs (_: server: server.headers != {}) config.programs.mcp.servers);

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
    # plain assignment.
    enabledPlugins = {
      "context-mode@context-mode" = lib.mkDefault true;
    };

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
  home = {
    packages = with perSystem.llm-agents; [
      # Used by codecompanion
      claude-agent-acp
    ];
  };

  programs.claude-code = {
    enable = true;
    package = perSystem.llm-agents.claude-code;
    enableMcpIntegration = true;

    inherit (ai) agents commands;
    inherit settings;

    # context-mode is the only marketplace we enable a plugin from; the curated
    # official-marketplace agents/commands are delivered through the native
    # `agents`/`commands` options above rather than Claude's native loader.
    marketplaces = {
      inherit (inputs) context-mode;
    };

    mcpServers = claudeMcpServers;

    configDir = "${config.xdg.configHome}/claude";

    context = ''
      ${builtins.readFile ./AGENTS.md}
      ${lib.optionalString config.programs.rtk.enable (builtins.readFile "${perSystem.llm-agents.rtk}/libexec/rtk/hooks/claude/rtk-awareness.md")}
    '';

    lspServers = claudeCodeLsp;
  };

  # The module would symlink settings.json read-only into the /nix/store, which
  # breaks runtime commands like /effort. Disable that and install a writable
  # copy of the module's own generated file instead (it already merges $schema
  # and extraKnownMarketplaces), so there's a single source of truth; each
  # activation overwrites it with declared state.
  home.file."${settingsPath}".enable = lib.mkForce false;

  home.activation.claudeCodeSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD install -Dm600 ${config.home.file."${settingsPath}".source} ${settingsPath}
  '';
}
