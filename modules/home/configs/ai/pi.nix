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

  # tintinweb/pi-subagents and teelicht/pi-superagents both own
  # extensions/subagent/; install exactly one. Superpowers integrates with the
  # teelicht fork, so track its enable state for pi.
  piSuperpowers = lib.elem "pi" config.programs.ai.superpowers.agents;

  rulesSkills = pkgs.linkFarm "pi-rules-skills" (lib.mapAttrsToList (file: _: let
    id = "${lib.removeSuffix ".md" file}-rules";
    parsed = builtins.match "---\npaths: \"([^\"]*)\"\n---\n+(.*)" (builtins.readFile (ai.rulesDir + "/${file}"));
  in {
    name = "${id}/SKILL.md";
    path = pkgs.writeText "${id}-SKILL.md" ''
      ---
      name: ${id}
      description: House coding rules. Load before reading or writing files matching ${builtins.elemAt parsed 0}.
      ---

      ${builtins.elemAt parsed 1}
    '';
  }) (lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".md" name) (builtins.readDir ai.rulesDir)));
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
        ai.superpowers.agents = ["pi"];

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

          context = builtins.readFile ./AGENTS.md;

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

            # pi has no path-scoped rules; ship them as on-demand skills instead of always-on context.
            skills = ["${rulesSkills}"];
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
                # "npm:context-mode"
                # Core skill only; the audit/debt/gain/help/review extras cost prompt tokens every turn.
                {
                  source = "npm:@dietrichgebert/ponytail";
                  skills = ["./skills/ponytail"];
                }
                "npm:@juicesharp/rpiv-ask-user-question"
                "npm:@juicesharp/rpiv-todo"
                "npm:@melihmucuk/pi-crew"
                "npm:pi-agent-browser-native"
                # "npm:pi-autoresearch"
                "npm:pi-background-tasks"
                "npm:pi-claude-marketplace"
                "npm:pi-hashline-readmap"
                # "npm:pi-lens"
                "npm:pi-mcp-adapter"
                "npm:pi-powerline-footer"
                # "npm:pi-tool-display" # https://github.com/MasuRii/pi-tool-display, Conflicts with pi-hashline-readmap
                # "npm:@pi-unipi/notify@2.20.1"
                "npm:pi-web-access"
                "npm:@sting8k/pi-vcc"
                "npm:@tifan/pi-copy-response@0.2.6"
                "npm:@tifan/pi-handoff"
                "npm:@tifan/pi-inline-skills"
                "npm:@tifan/pi-rename"
                "npm:@vanillagreen/pi-skills-manager"
              ]
              ++ lib.optional (!piSuperpowers) "npm:@tintinweb/pi-subagents"
              ++ lib.optional piSuperpowers "npm:@teelicht/pi-superagents"
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
