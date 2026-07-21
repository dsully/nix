{
  ai,
  config,
  inputs,
  lib,
  pkgs,
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

  settings = {
    inherit (ai.models.large) model;

    autoUpdates = false;
    effortLevel = "medium";
    enableAllProjectMcpServers = false;
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
      command = lib.getExe pkgs.llm-agents.ccstatusline;
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
  config = lib.mkMerge [
    {programs.claude-code.enable = lib.mkDefault true;}

    (lib.mkIf config.programs.claude-code.enable {
      home = {
        packages = with pkgs.llm-agents; [
          # Used by codecompanion
          claude-agent-acp
        ];

        # Point the legacy ~/.claude paths at the XDG location, which is the single
        # source of truth (configDir below).
        file = {
          ".claude".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/claude";
          ".claude.json".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/claude/.claude.json";
        };
      };

      programs.claude-code = {
        package = pkgs.llm-agents.claude-code;

        enableMcpIntegration = true;

        inherit (ai) agents commands;
        inherit settings;

        # context-mode is the only marketplace we enable a plugin from; the curated
        # official-marketplace agents/commands are delivered through the native
        # `agents`/`commands` options above rather than Claude's native loader.
        marketplaces = {
          inherit (inputs) context-mode;
        };

        configDir = "${config.xdg.configHome}/claude";

        context = ''
          ${builtins.readFile ./AGENTS.md}
          ${lib.optionalString config.programs.rtk.enable (builtins.readFile "${pkgs.llm-agents.rtk}/libexec/rtk/hooks/claude/rtk-awareness.md")}
        '';

        # Language-specific rules loaded on-demand via `paths:` frontmatter.
        rulesDir = ai.rulesDir;

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
    })
  ];
}
