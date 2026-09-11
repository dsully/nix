{
  ai,
  config,
  lib,
  pkgs,
  wrapperLib,
  ...
}: let
  jsonFormat = pkgs.formats.json {};
  piPath = "${config.home.homeDirectory}/.pi/agent";

  rewriteEnvPlaceholders = lib.replaceStrings ["{env:"] ["\${"];
  rewriteMcpValue = value:
    if builtins.isString value
    then rewriteEnvPlaceholders value
    else if builtins.isAttrs value
    then lib.mapAttrs (_: rewriteMcpValue) value
    else if builtins.isList value
    then map rewriteMcpValue value
    else value;

  # Normalize via lib.hm.mcp.transformMcpServer to drop the typed schema's null
  # and empty-default fields and resolve `enabled`. pi consumes the legacy
  # `disabled` flag (which transformMcpServer strips), so re-attach it afterwards.
  piMcpServer = server: let
    authorization = server.headers.Authorization or null;
    headersWithoutAuthorization = lib.removeAttrs server.headers ["Authorization"];
    bearerEnv =
      if builtins.isString authorization
      then builtins.match "Bearer [{]env:([A-Za-z_][A-Za-z0-9_]*)[}]" authorization
      else null;

    transformed = lib.hm.mcp.transformMcpServer {
      inherit server;
      exclude = ["enabled"];
      extraTransforms = [
        (s:
          if bearerEnv == null
          then rewriteMcpValue s
          else
            (rewriteMcpValue (
              (lib.removeAttrs s ["headers"])
              // lib.optionalAttrs (headersWithoutAuthorization != {}) {
                headers = headersWithoutAuthorization;
              }
            ))
            // {
              auth = "bearer";
              bearerTokenEnv = builtins.head bearerEnv;
            })
      ];
    };
  in
    transformed // lib.optionalAttrs (server.enabled == false) {disabled = true;};

  piMcpServers = lib.mapAttrs (_: piMcpServer) config.programs.mcp.servers;
in {
  imports = [
    ./pi/theme.nix
  ];

  config = lib.mkMerge [
    {programs.pi-coding-agent.enable = lib.mkDefault true;}

    (lib.mkIf config.programs.pi-coding-agent.enable {
      home = {
        file = {
          "${piPath}/mcp.json" = lib.mkIf (piMcpServers != {}) {
            source = jsonFormat.generate "pi-mcp.json" {
              mcpServers = piMcpServers;
            };
          };

          # pi-lens owns diagnostics + LSP, but not file mutation: its autoformat
          # would biome-format .ts (its JS/TS default) and fight the oxfmt
          # PostToolUse hook in hooks.nix, and its autofix runs biome/ruff/eslint
          # --fix. Turn both off so the hook is the single formatter of record;
          # LSP, lint dispatch, and diagnostics stay on. Read-only file is fine —
          # pi-lens only reads this, never rewrites it.
          ".pi-lens/config.json".source = jsonFormat.generate "pi-lens-config.json" {
            format.enabled = false;
            autofix.enabled = false;
          };
        };
      };

      programs = {
        agent-skills.targets.pi.enable = true;

        pi-coding-agent = {
          package = wrapperLib.wrapPackage {
            inherit pkgs;
            package = pkgs.llm-agents.pi;

            envDefault = {
              # PI_CONFIG_DIR = ;
              PI_SKIP_VERSION_CHECK = "1";
              PI_TELEMETRY = "0";
              POWERLINE_NERD_FONTS = "1";
            };
          };

          context = ''
            ${builtins.readFile ./AGENTS.md}
            ${ai.rulesMarkdown}
          '';

          settings = {
            collapseChangelog = true;

            compaction = {
              enabled = true;
              reserveTokens = 16384;
              keepRecentTokens = 20000;
            };

            defaultModel = ai.models.large.model;
            defaultProvider = ai.models.large.provider;
            defaultThinkingLevel = ai.models.large.reasoning_effort;

            enableInstallTelemetry = false;
            enableSkillCommands = false;
            hideThinkingBlock = true;
            hooks = ai.hooks.pi;
            quietStartup = true;
            skipApprovals = true;

            powerline = {
              preset = "nerd";
              separator = "slash";
              welcome = true;

              layout = {
                left = ["model" "thinking" "path"];
                right = ["context_pct" "subagents"];
              };

              model.showThinkingLevel = false;
              path.mode = "basename";

              git = {
                showBranch = false;
                showStaged = false;
                showUnstaged = false;
                showUntracked = false;
              };
            };

            npmCommand = [(lib.getExe config.programs.bun.package)];
            packages = lib.unique (
              [
                # "npm:pi-hashline-edit-pro@4.2.3" # https://github.com/YuGiMob/pi-hashline-edit-pro
                # "npm:pi-lens@4.1.5"
                "npm:context-mode@1.0.169"
                "npm:@juicesharp/rpiv-ask-user-question@2.9.0"
                "npm:@juicesharp/rpiv-todo@2.9.0"
                "npm:pi-agent-browser-native@0.6.10"
                "npm:pi-background-tasks@2.5.0"
                "npm:pi-browser-use@0.11.3"
                "npm:pi-claude-marketplace@0.18.3"
                "npm:pi-mcp-adapter@2.32.1"
                "npm:pi-powerline-footer@0.17.0"
                "npm:pi-subagents@0.67.0"
                "npm:pi-tool-display@0.5.0" # https://github.com/MasuRii/pi-tool-display
                "npm:@pi-unipi/notify@2.16.0"
                "npm:pi-web-access@0.28.0"
                "npm:@vanillagreen/pi-skills-manager@2.0.1"
              ]
              ++ lib.optional config.programs.rtk.enable "npm:pi-rtk-optimizer@0.9.0"
              ++ lib.optional config.programs.icm.enable "npm:pi-icm-hook@0.1.2"
            );

            terminal = {
              showTerminalProgress = true;
            };

            theme = "nord";
          };
        };
      };
    })
  ];
}
