{
  ai,
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
in {
  # home-manager doesn't write here. :(
  # home.sessionVariables.CLAUDE_CONFIG_DIR = "${config.xdg.configHome}/claude";

  programs.claude-code = {
    enable = true;
    package = perSystem.llm-agents.claude-code;
    enableMcpIntegration = true;

    inherit (ai) agents;

    context = ./AGENTS.md;

    settings = {
      inherit (ai.models.large) model;

      autoUpdates = false;
      enableAllProjectMcpServers = false;
      enableMcpIntegration = true;
      includeCoAuthoredBy = false;

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

      skipAutoPermissionPrompt = true;
    };

    lspServers = claudeCodeLsp;
  };
}
