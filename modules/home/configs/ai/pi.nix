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
                "git:github.com/paoloanzn/pi-black@v0.84.1-cc2.1.258.1"

                # https://github.com/YuGiMob/pi-hashline-edit-pro
                # "npm:pi-hashline-edit-pro@4.2.3"

                "npm:pi-mcp-adapter@2.32.1"
                "npm:pi-subagents@0.67.0"
                "npm:pi-web-access@0.28.0"

                # omp: lsp tool + lsp.formatOnWrite (and partial ast_grep/ast_edit).
                # Talks to a dozen-plus language servers: diagnostics + navigation
                # tools, format/autofix on every write (runs your project's
                # formatter, not just LSP), tree-sitter/ast-grep structural rules,
                # symbol_search, read-guard. For an explicit definition/references/
                # rename/code_actions surface instead, npm:pi-lsp-bridge is the
                # dedicated per-server bridge — but both spawn servers, so run one.
                # "npm:pi-lens@4.1.5"

                # omp: bash background jobs + hub-supervised processes
                "npm:pi-background-tasks@2.5.0"

                # omp: eval (sandboxed code execution) + read summarization / KB
                "npm:context-mode@1.0.169"

                # omp: ask tool
                "npm:@juicesharp/rpiv-ask-user-question@2.9.0"

                # omp: todo tool (live overlay, survives compaction)
                "npm:@juicesharp/rpiv-todo@2.9.0"

                # "npm:@narumitw/pi-goal@0.54.4"

                # omp: custom powerline statusLine (model/path/git/context/timer)
                # "npm:pi-powerline@0.9.1"
                "npm:pi-powerline-footer@0.17.0"

                # "npm:@agnishc/edb-session-manager@0.21.1"

                # omp: manage_skill + native skill browsing
                "npm:@vanillagreen/pi-skills-manager@2.0.1"

                # omp: retry.waitForUsageReset (resume after usage limit)
                # "npm:pi-continue@0.9.3"

                # omp TUI parity: rich tool cards, sticky composer, side questions
                "npm:pi-tool-display@0.5.0"
                # "npm:pi-sticky-input@0.2.0"
                # "npm:pi-sticky-prompt@0.1.3"
                # "npm:pi-qq@0.1.17"

                # "npm:@hsingjui/pi-hooks@0.0.2"
                "npm:@pi-unipi/notify@2.16.0"

                # Optional — enable per need:
                # "npm:pi-agent-browser-native@0.6.10" # omp: browser (heavy; or npm:pi-chrome for real Chrome)
                # "npm:pi-memory@0.4.2"               # omp: memory backend — you keep memory OFF in omp
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
