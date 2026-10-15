{
  mkUserModule,
  ai,
  config,
  lib,
  my,
  pkgs,
  wrapperLib,
  ...
}: let
  jsonFormat = pkgs.formats.json {};
  piPath = "${config.xdg.configHome}/pi/agent";

  # Normalize via lib.hm.mcp.transformMcpServer to drop the typed schema's null
  # and empty-default fields and add the exposure key/value.
  piMcpServers = lib.mapAttrs (_: server:
    lib.hm.mcp.transformMcpServer {inherit server;}
    // {exposure = "deferred";}
    // lib.optionalAttrs (server.enabled == false) {disabled = true;})
  config.programs.mcp.servers;

  # tintinweb/pi-subagents and teelicht/pi-superagents both own
  # extensions/subagent/; install exactly one. Superpowers integrates with the
  # teelicht fork, so track its enable state for pi.
  piSuperpowers = lib.elem "pi" config.programs.ai.superpowers.agents;

  piMemory = lib.any (p: lib.isString p && lib.hasPrefix "npm:@pi-unipi/memory" p) (config.programs.pi-coding-agent.settings.packages or []);

  piExtensions =
    lib.filterAttrs (name: type: (type == "directory" || (type == "regular" && lib.hasSuffix ".ts" name)))
    (builtins.readDir ../../../dotfiles/pi/extensions);

  rulesSkills = pkgs.linkFarm "pi-rules-skills" (lib.mapAttrsToList (file: _: let
    id = "${lib.removeSuffix ".md" file}-rules";
    parsed = builtins.match "---\npaths: \"([^\"]*)\"\n---\n+(.*)" (builtins.readFile (ai.rulesDir + "/${file}"));
  in {
    name = "${id}/SKILL.md";
    needs = ["ai"];
    path = pkgs.writeText "${id}-SKILL.md" ''
      ---
      name: ${id}
      description: House coding rules. Load before reading or writing files matching ${builtins.elemAt parsed 0}.
      ---

      ${builtins.elemAt parsed 1}
    '';
  }) (lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".md" name) (builtins.readDir ai.rulesDir)));

  bunExe = lib.getExe config.programs.bun.package;
  bunRuntime = pkgs.symlinkJoin {
    name = "bun-runtime";
    meta.mainProgram = "bun";

    paths = [
      (pkgs.writeShellScriptBin "bun" ''
        if [[ "''${1-}" == install ]]; then
          exec ${bunExe} "$@" --trust
        fi
        exec ${bunExe} "$@"
      '')
    ];

    postBuild = ''
      ln -s ${bunExe} $out/bin/node
    '';
  };
in
  mkUserModule {
    name = "pi";
    default = false;

    homeOptions.programs.pi-coding-agent.excludePackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Package sources removed from the default pi packages list.";
    };

    home = lib.mkMerge [
      (import ./theme.nix {inherit config lib pkgs piPath;}).config
      {
        _module.args.piPath = piPath;
        programs.pi-coding-agent.enable = lib.mkDefault true;
      }

      (lib.mkIf config.programs.pi-coding-agent.enable {
        home = {
          # Live symlinks: edits in the working tree apply on /reload, no switch.
          file =
            lib.mapAttrs' (name: _:
              lib.nameValuePair "${piPath}/extensions/${name}" {
                source = config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.dir}/pi/extensions/${name}";
              })
            piExtensions
            // {
              ".pi".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/pi";

              "${piPath}/mcp.json".source = jsonFormat.generate "pi-mcp.json" {
                mcpServers = piMcpServers;
              };

              "${piPath}/mcp-adapter.json".source = jsonFormat.generate "pi-mcp-adapter.json" {
                settings = {
                  deferWithMissingMetadata = true;
                  namespaceProxyTools = false;
                };
              };

              "${piPath}/compact-tools.json".source = jsonFormat.generate "pi-compact-tools.json" {
                "$schema" = "https://raw.githubusercontent.com/nedleeds/pi-compact-tools/main/schemas/compact-tools.schema.json";
                auto_compact = {
                  bash = true;
                  edit = false;
                  read = true;
                  write = true;
                };
                custom_tools = {
                  enabled = true;
                  auto_compact = true;
                  exclude = [];
                };
                mode = "normal";
                previewLines = 1;
                style = "claude";
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

          activation = {
            # Install/update the extensions listed in settings.json. Runs after
            # onFilesChange so settings.json is written and any bunfig onChange
            # hook has already run.
            # context-mode pulls better-sqlite3, a native module bun builds from
            # source (bun disables prebuild-install), so node-gyp needs Python and
            # the system toolchain. Activation runs with a stripped PATH, so add
            # Python here; clang/make come from the inherited PATH (Xcode CLT).
            # Retry a few times to ride out transient registry failures.
            # Non-fatal: a persistent failure warns, never aborts the switch.
            piUpdateExtensions = lib.hm.dag.entryAfter ["onFilesChange"] ''
              export PATH="${lib.makeBinPath [config.programs.bun.package pkgs.python3 pkgs.git]}:$PATH"
              export PYTHON="${lib.getExe pkgs.python3}"
              export PI_CODING_AGENT_DIR="${piPath}"
              _ok=

              for _try in 1 2 3; do
                if run ${config.programs.pi-coding-agent.package}/bin/pi update --extensions; then
                  _ok=1
                  break
                fi

                echo "pi update --extensions attempt $_try failed; retrying in 5s..."
                sleep 5
              done

              [ -n "$_ok" ] || echo "pi update --extensions failed after 3 tries; run it manually to see errors"
            '';

            # mempalace breaks on Python 3.15; uv records --python in the tool
            # receipt, so uvTool's later install/upgrade keep this interpreter.
            mempalacePython = lib.mkIf piMemory (lib.hm.dag.entryBetween ["uvTool"] ["linkGeneration"] ''
              run ${lib.getExe config.programs.uv.package} tool install $VERBOSE_ARG --python 3.14 mempalace
            '');
          };
        };

        programs = {
          agent-skills.targets.pi.enable = true;
          ai.superpowers.agents = ["pi"];

          pi-coding-agent = {
            package = wrapperLib.wrapPackage {
              inherit pkgs;
              package = my.pkgs.pi-bolt;

              envDefault = {
                PI_CLIPBOARD_OSC52 = "1";
                PI_CODING_AGENT_DIR = piPath;
                PI_SKIP_VERSION_CHECK = "1";
                PI_TELEMETRY = "0";
                POWERLINE_NERD_FONTS = "1";
              };
            };

            configDir = piPath;

            context = builtins.readFile ../shared/AGENTS.md;

            # Ctrl+R opens the prompt-history picker from extensions/history.ts.
            keybindings."app.session.rename" = [];

            settings = {
              "$schema" = "https://pi.dev/schemas/settings.schema.json";
              collapseChangelog = true;

              compaction = {
                enabled = true;
                reserveTokens = 16384;
                keepRecentTokens = 20000;
              };

              defaultModel = ai.models.large.model;
              defaultProvider = ai.models.large.provider;
              defaultThinkingLevel = ai.models.large.reasoning_effort;
              defaultTools = [
                "+codemode"
              ];

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

              npmCommand = [(lib.getExe bunRuntime)];

              packages = lib.subtractLists config.programs.pi-coding-agent.excludePackages (lib.unique (
                [
                  # "npm:context-mode"
                  # Core skill only; the audit/debt/gain/help/review extras cost prompt tokens every turn.
                  {
                    source = "npm:@dietrichgebert/ponytail";
                    skills = ["./skills/ponytail"];
                  }
                  "npm:@injaneity/pi-computer-use"
                  "npm:@optomatica/pi-auto-session-name"
                  # "npm:pi-agent-browser-native"
                  # "npm:pi-autoresearch"
                  # "npm:pi-blackhole"
                  "npm:pi-codemode-toggle"
                  "npm:pi-compact-tools"
                  "npm:pi-context-view"
                  "npm:pi-hashline-edit-pro-lean"
                  "npm:pi-inspector"
                  "npm:@pi-unipi/background-tasks@alpha"
                  "npm:@pi-unipi/compactor@alpha"
                  "npm:@pi-unipi/memory@alpha"
                  "npm:@pi-unipi/notify@alpha"
                  "npm:@ssk_dev/pi-docs-slim"
                  "npm:@ssk_dev/rpiv-ask-user-question-lean"
                  "npm:@ssk_dev/rpiv-todo-lean"
                  "npm:@tifan/pi-copy-response"
                  "npm:@tifan/pi-handoff"
                  "npm:@tifan/pi-recap"
                  "npm:@vanillagreen/pi-skills-manager"
                ]
                ++ lib.optional (!piSuperpowers) "npm:@ssk_dev/pi-subagents-lean"
                ++ lib.optional piSuperpowers "npm:@teelicht/pi-superagents"
              ));

              terminal = {
                showTerminalProgress = true;
              };

              theme = "nord";
            };
          };

          uv.tool.packages = lib.mkIf piMemory [
            "mempalace"
          ];
        };
      })
    ];
  }
