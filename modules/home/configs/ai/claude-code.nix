{
  config,
  inputs,
  lib,
  my,
  perSystem,
  pkgs,
  ...
}: let
  aiLib = import ./lib.nix {inherit config inputs lib my perSystem pkgs;};
  aiAgents = import ./agents.nix {inherit aiLib inputs lib;};
in {
  # Generate the rtk-rewrite.sh hook script without patching settings.json
  home.activation.rtkClaudeHook = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${lib.getExe perSystem.llm-agents.rtk} init --global --hook-only --agent claude --no-patch >/dev/null 2>&1 || true
  '';

  programs.claude-code = {
    enable = true;
    package = perSystem.llm-agents.claude-code;

    inherit (aiAgents) agents;

    context = ./AGENTS.md;

    settings = {
      inherit (aiLib.models.large) model;

      autoUpdates = false;
      enableAllProjectMcpServers = false;
      enableMcpIntegration = true;
      includeCoAuthoredBy = false;

      extraKnownMarketplaces = {
        "astral-sh" = {
          source = {
            source = "directory";
            path = "${aiLib.acp}";
          };
        };
        claude-code-workflows = {
          source = {
            source = "directory";
            path = "${inputs.wshobson-agents}";
          };
        };
      };

      enabledPlugins =
        {
          "astral@astral-sh" = lib.mkDefault true;
          "code-review@claude-plugins-official" = lib.mkDefault true;
          "code-simplifier@claude-plugins-official" = lib.mkDefault true;
          "commit-commands@claude-plugins-official" = lib.mkDefault true;
          "feature-dev@claude-plugins-official" = lib.mkDefault true;
          "pr-review-toolkit@claude-plugins-official" = lib.mkDefault true;
          "ralph-loop@claude-plugins-official" = lib.mkDefault true;
          "rust-analyzer-lsp@claude-plugins-official" = lib.mkDefault true;
        }
        // aiAgents.enabledPlugins;

      hooks = lib.mkDefault {
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
                command = "${config.home.homeDirectory}/.claude/hooks/rtk-rewrite.sh";
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
        CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING = "1";
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
        CLAUDE_CODE_EFFORT_LEVEL = "max";
        DISABLE_AUTOUPDATER = "1";
        DISABLE_BUG_COMMAND = "1";
        DISABLE_ERROR_REPORTING = "1";
        DISABLE_TELEMETRY = "1";
        ENABLE_TOOL_SEARCH = "1";
        MAX_THINKING_TOKENS = "127999";
      };
    };

    lspServers = aiLib.claudeCodeLsp;

    mcpServers = aiLib.mcpServersWithType;
  };
}
