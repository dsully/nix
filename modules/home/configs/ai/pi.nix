{
  ai,
  config,
  lib,
  perSystem,
  pkgs,
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

          "${piPath}/themes/nord.json".source = ./pi/nord.json;
        };

        sessionVariables = {
          PI_SKIP_VERSION_CHECK = "1";
          PI_TELEMETRY = "0";
        };
      };

      programs.pi-coding-agent = {
        package = perSystem.llm-agents.pi;

        context = ./AGENTS.md;

        settings = {
          collapseChangelog = true;
          defaultModel = ai.models.large.model;
          defaultProvider = ai.models.large.provider;
          defaultThinkingLevel = ai.models.large.reasoning_effort;

          enableInstallTelemetry = false;
          enableSkillCommands = false;
          hideThinkingBlock = true;
          hooks = ai.hooks.pi;
          quietStartup = true;
          skipApprovals = true;

          npmCommand = [(lib.getExe config.programs.bun.package)];
          packages = lib.unique (
            [
              "npm:@agnishc/edb-session-manager"
              # "npm:@aliou/pi-processes"
              "npm:@gotgenes/pi-subagents"
              "npm:@hsingjui/pi-hooks"
              "npm:@juicesharp/rpiv-ask-user-question"
              "npm:@juicesharp/rpiv-btw"
              "npm:@narumitw/pi-goal"
              "npm:context-mode"
              "npm:pi-continue"
              # "npm:pi-fff"
              "npm:pi-icm-hook"
              "npm:pi-lens"
              "npm:pi-mcp-adapter"
              "npm:pi-mermaid"
              "npm:pi-permission-system"
              # "npm:pi-powerline"
              # "npm:pi-powerline-melbourne"
              "npm:pi-qq"
              "npm:pi-session-exporter"
              "npm:pi-simplify"
              "npm:pi-sticky-input"
              "npm:pi-sticky-prompt" # Has optional macOS/Swift companion
              "npm:pi-tool-display"
              # "npm:pi-vitals"
              "npm:@pi-unipi/notify"
              "npm:@vanillagreen/pi-skills-manager"
            ]
            ++ lib.optional config.programs.rtk.enable "npm:pi-rtk-optimizer"
          );

          terminal = {
            showTerminalProgress = true;
          };

          theme = "nord";
        };
      };
    })
  ];
}
