{
  ai,
  config,
  lib,
  pkgs,
  wrapperLib,
  ...
}: let
  jsonFormat = pkgs.formats.json {};
  piPath = "${config.xdg.configHome}/pi/agent";

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
    {
      _module.args.piPath = piPath;
      programs.pi-coding-agent.enable = lib.mkDefault true;
    }

    (lib.mkIf config.programs.pi-coding-agent.enable {
      home = {
        file = {
          ".pi".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/pi";

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
          # ".pi-lens/config.json".source = jsonFormat.generate "pi-lens-config.json" {
          #   format.enabled = false;
          #   autofix.enabled = false;
          # };
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

          configDir = piPath;

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
            packages = lib.unique [
              "npm:context-mode"
              "npm:@juicesharp/rpiv-ask-user-question"
              "npm:@juicesharp/rpiv-todo"
              "npm:pi-agent-browser-native"
              "npm:pi-autoresearch"
              "npm:pi-background-tasks"
              # "npm:pi-browser-use"
              "npm:pi-claude-marketplace"
              # "npm:pi-hashline-edit-pro" # https://github.com/YuGiMob/pi-hashline-edit-pro
              # "npm:pi-lens"
              "npm:pi-mcp-adapter"
              "npm:pi-ponytail"
              "npm:pi-powerline-footer"
              "npm:pi-tool-display" # https://github.com/MasuRii/pi-tool-display
              "npm:@pi-unipi/notify"
              "npm:pi-web-access"
              "npm:@sting8k/pi-vcc"
              "npm:@tintinweb/pi-subagents"
              "npm:@vanillagreen/pi-skills-manager"
            ];

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
