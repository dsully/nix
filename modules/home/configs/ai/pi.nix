{
  ai,
  config,
  lib,
  perSystem,
  pkgs,
  ...
}: let
  piPackage = perSystem.llm-agents.pi;
  jsonFormat = pkgs.formats.json {};
  hasBuiltInExtensions =
    builtins.pathExists "${piPackage}/examples/extensions"
    || builtins.pathExists "${piPackage}/lib/node_modules/pi-monorepo/examples/extensions";

  rewriteEnvPlaceholders = lib.replaceStrings ["{env:"] ["\${"];
  rewriteMcpValue = value:
    if builtins.isString value
    then rewriteEnvPlaceholders value
    else if builtins.isAttrs value
    then lib.mapAttrs (_: rewriteMcpValue) value
    else if builtins.isList value
    then map rewriteMcpValue value
    else value;

  piMcpServer = server: let
    authorization = server.headers.Authorization or null;
    headersWithoutAuthorization = lib.removeAttrs (server.headers or {}) ["Authorization"];
    bearerEnv =
      if builtins.isString authorization
      then builtins.match "Bearer [{]env:([A-Za-z_][A-Za-z0-9_]*)[}]" authorization
      else null;
  in
    if bearerEnv == null
    then rewriteMcpValue server
    else
      (rewriteMcpValue (
        (lib.removeAttrs server ["headers"])
        // lib.optionalAttrs (headersWithoutAuthorization != {}) {
          headers = headersWithoutAuthorization;
        }
      ))
      // {
        auth = "bearer";
        bearerTokenEnv = builtins.elemAt bearerEnv 0;
      };

  piMcpServers = lib.mapAttrs (_: piMcpServer) config.programs.mcp.servers;
in {
  imports = [
    ../../pi.nix
  ];

  home.file."${config.home.homeDirectory}/.pi/agent/mcp.json" = lib.mkIf (piMcpServers != {}) {
    source = jsonFormat.generate "pi-mcp.json" {
      mcpServers = piMcpServers;
    };
  };

  programs.pi = {
    enable = true;

    agentsMd = builtins.readFile ./AGENTS.md;

    builtInExtensions = lib.mkIf hasBuiltInExtensions {
      permissionGate = true;
      protectedPaths = true;
      confirmDestructive = true;
      dirtyRepoGuard = true;

      todo = false;

      notify = false;
      statusLine = false;
      modelStatus = false;

      inlineBash = true;
      tools = true;
      handoff = true;
      qna = true;

      titlebarSpinner = true;
      triggerCompact = true;
      sessionName = true;
      preset = true;
    };

    packageExtensions = [
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
      "npm:pi-rtk-optimizer"
      "npm:pi-session-exporter"
      "npm:pi-simplify"
      "npm:pi-sticky-input"
      "npm:pi-sticky-prompt" # Has optional macOS/Swift companion
      "npm:pi-tool-display"
      # "npm:pi-vitals"
      "npm:@pi-unipi/notify"
      "npm:@vanillagreen/pi-skills-manager"
    ];

    # extensions = [
    #   ./pi/autocomplete-above-editor.ts
    # ];

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

      terminal = {
        showTerminalProgress = true;
      };

      theme = "nord";
    };

    themes = [
      ./pi/nord.json
    ];
  };
}
