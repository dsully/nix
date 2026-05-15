{
  ai,
  config,
  lib,
  my,
  perSystem,
  pkgs,
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

  settings = {
    inherit (ai.models.large) model;

    autoUpdates = false;
    effortLevel = "medium";
    enableAllProjectMcpServers = false;
    enableMcpIntegration = true;
    includeCoAuthoredBy = false;

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

    hooks = lib.mkDefault {
      PreCompact = [
        {
          hooks = [
            {
              type = "command";
              command = "${lib.getExe my.pkgs.icm} hook compact";
            }
          ];
        }
      ];
      PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = ./hooks/enforce-uv.fish;
            }
            {
              type = "command";
              command = "${perSystem.llm-agents.rtk}/libexec/rtk/hooks/claude/rtk-rewrite.sh";
            }
            {
              type = "command";
              command = "${lib.getExe my.pkgs.icm} hook pre";
            }
          ];
        }
      ];
      PostToolUse = [
        {
          matcher = "Edit|Write|MultiEdit";
          hooks = [
            {
              command =
                # bash
                ''
                  file_path="$1"
                  case "$file_path" in
                    *.nix)   ${lib.getExe pkgs.alejandra} "$file_path" 2>/dev/null || true ;;
                    *.py)    ${lib.getExe pkgs.ruff} format "$file_path" 2>/dev/null || true ;;
                    *.rs)    rustfmt +nightly "$file_path" 2>/dev/null || true ;;
                  esac
                '';
              timeout = 10;
              type = "command";
            }
            {
              type = "command";
              command = "${lib.getExe my.pkgs.icm} hook post";
            }
          ];
        }
      ];
      SessionStart = [
        {
          hooks = [
            {
              type = "command";
              command = "${lib.getExe my.pkgs.icm} hook start";
            }
          ];
        }
      ];
      UserPromptSubmit = [
        {
          hooks = [
            {
              type = "command";
              command = "${lib.getExe my.pkgs.icm} hook prompt";
            }
          ];
        }
      ];
    };

    statusLine = {
      command = lib.getExe perSystem.llm-agents.ccstatusline;
      padding = 0;
      type = "command";
    };

    permissions = {
      allow = [
        "Bash(ast-grep *)"
        "Bash(awk *)"
        "Bash(cargo *)"
        "Bash(curl *)"
        "Bash(fd *)"
        "Bash(jq *)"
        "Bash(just *)"
        "Bash(nix *)"
        "Bash(rg *)"
        "Edit(**/*.md)"
        "Edit(//tmp/**)"
        "Glob"
        "Grep"
        "Read(//tmp/**)"
        "Read(~/.claude/skills/**)"
        "Read(~/.config/claude/skills/**)"
        "Read(~/dev/**)"
        "Skill(ast-grep)"
        "Task"
        "WebFetch"
        "WebSearch"
        "Write(//tmp/**)"
        "Write(**/plans/**)"
      ];

      ask = [
        "Bash(rm)"
        "Bash(rmdir)"
        "Read(./secrets/**)"
      ];

      deny = [
        "Bash(git)"
        "Bash(su)"
        "Bash(sudo)"
        "Read(./.direnv)"
        "Read(./.env)"
        "Read(./.env.*)"
        "Read(./.envrc)"
        "Read(./build)"
        "Read(./config/credentials.json)"
        "Read(./target)"
        "Read(~/.aws)"
        "Read(~/.cache)"
        "Read(~/.cargo)"
        "Read(~/.ssh)"
      ];

      additionalDirectories = [
        "/tmp"
        "/var"
      ];

      defaultMode = "plan";
      disableBypassPermissionsMode = "disable";
    };

    env = {
      CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
      DISABLE_AUTOUPDATER = "1";
      DISABLE_BUG_COMMAND = "1";
      DISABLE_ERROR_REPORTING = "1";
      DISABLE_TELEMETRY = "1";
      ENABLE_TOOL_SEARCH = "1";
    };

    skipAutoPermissionPrompt = true;
  };

  # Generated the same way the home-manager module would, but installed as a
  # mutable copy below instead of a read-only /nix/store symlink. Reads the
  # fully-merged option value so downstream flake overrides are included.
  settingsFile = (pkgs.formats.json {}).generate "claude-code-settings.json" (
    config.programs.claude-code.settings
    // {
      "$schema" = "https://json.schemastore.org/claude-code-settings.json";
    }
  );

  settingsPath = "${config.xdg.configHome}/claude/settings.json";
in {
  programs.claude-code = {
    enable = true;
    package = perSystem.llm-agents.claude-code;
    enableMcpIntegration = true;

    inherit (ai) agents;
    inherit settings;

    configDir = "${config.xdg.configHome}/claude";
    context = ./AGENTS.md;

    lspServers = claudeCodeLsp;
  };

  # The module would symlink settings.json read-only into the /nix/store,
  # which breaks runtime commands like /effort. Disable that and install a
  # writable copy of the fully-merged settings instead (so downstream flakes
  # that override programs.claude-code.settings still take effect).
  home.file.".config/claude/settings.json".enable = lib.mkForce false;

  home.activation.claudeCodeSettings = lib.hm.dag.entryAfter ["linkGeneration"] ''
    $DRY_RUN_CMD rm $VERBOSE_ARG -f ${settingsPath}
    $DRY_RUN_CMD install $VERBOSE_ARG -Dm644 ${settingsFile} ${settingsPath}
  '';
}
