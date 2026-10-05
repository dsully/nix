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
    skipDangerousModePermissionPrompt = true;

    outputStyle = ai.defaultOutputStyle;

    # Keys below are mkDefault, so a downstream flake can override them with a
    # plain assignment.
    enabledPlugins = {
      "context-mode@context-mode" = lib.mkDefault true;
      "ponytail@ponytail" = lib.mkDefault true;
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
      CLAUDE_CODE_ENABLE_TODO_TOOLS = "1";
      CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
      # https://code.claude.com/docs/en/fullscreen
      CLAUDE_CODE_NO_FLICKER = "1";
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
        # context-mode npm-installs into its plugin dir (store is read-only), and HM `marketplaces` overwrites settings.extraKnownMarketplaces.
        activation.claudeContextModeMarketplace = lib.hm.dag.entryAfter ["claudeCodeSettings"] ''
          tmp=$(mktemp)
          ${lib.getExe pkgs.jq} '.extraKnownMarketplaces["context-mode"].source = {
            source: "github",
            repo: "mksglu/context-mode",
            ref: "v${ai.contextModeVersion}"
          }' ${settingsPath} > "$tmp"
          run install -m600 "$tmp" ${settingsPath}
          rm -f "$tmp"
        '';

        # Point the legacy ~/.claude paths at the XDG location, which is the single
        # source of truth (configDir below).
        file = {
          ".claude".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/claude";
          ".claude.json".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/claude/.claude.json";
        };

        packages = with pkgs.llm-agents; [
          # Used by codecompanion
          claude-agent-acp
        ];
      };

      programs = {
        agent-skills.targets.claude.enable = true;
        ai.superpowers.agents = ["claude"];

        claude-code = {
          package = pkgs.llm-agents.claude-code;
          mutableSettings = true;

          enableMcpIntegration = true;

          inherit (ai) agents commands outputStyles;
          inherit settings;

          # The curated official-marketplace agents/commands are delivered through
          # the native `agents`/`commands` options above rather than Claude's
          # native loader.
          marketplaces = {
            inherit (inputs) ponytail;
          };

          configDir = "${config.xdg.configHome}/claude";

          context = ''
            ${builtins.readFile ./AGENTS.md}
          '';

          # Language-specific rules loaded on-demand via `paths:` frontmatter.
          inherit (ai) rulesDir;

          lspServers = claudeCodeLsp;
        };
      };
    })
  ];
}
