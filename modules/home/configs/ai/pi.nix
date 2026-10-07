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

          "${piPath}/mcp.json".source = jsonFormat.generate "pi-mcp.json" {
            mcpServers = piMcpServers;
          };

          "${piPath}/mcp-adapter.json".source = jsonFormat.generate "pi-mcp-adapter.json" {
            settings = {
              deferWithMissingMetadata = true;
              namespaceProxyTools = false;
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

          # @pi-unipi/footer delays the glance editor 3.5s as a grace period for
          # unipi's info-screen (not installed); drop it. sed -i replaces the file,
          # so bun's cache is untouched. Warns if upstream changes the line.
          piPatchUnipiFooter = lib.hm.dag.entryAfter ["piUpdateExtensions"] ''
            _f="${piPath}/npm/node_modules/@pi-unipi/footer/src/index.ts"
            _from='installGlanceEditor(state, ctx), 3500)'

            if [ -f "$_f" ]; then
              if ${lib.getExe pkgs.gnugrep} -qF "$_from" "$_f"; then
                run ${lib.getExe pkgs.gnused} -i 's/installGlanceEditor(state, ctx), 3500)/installGlanceEditor(state, ctx), 0)/' "$_f"
              elif ! ${lib.getExe pkgs.gnugrep} -qF 'installGlanceEditor(state, ctx), 0)' "$_f"; then
                echo "piPatchUnipiFooter: pattern not found in $_f; glance delay patch not applied"
              fi
            fi
          '';

          # Fullscreen: render the glance editor's autocomplete as an overlay above
          # the frame instead of inline below it, so neither the frame nor the
          # transcript moves. Reverse dry-run detects an already-patched tree.
          # Regenerate from a UniPi checkout (github.com/Neuron-Mr-White/UniPi) at the
          # installed footer version, with the change applied to src/glance-editor.ts:
          #   git diff --relative=packages/footer -- packages/footer/src/glance-editor.ts \
          #     > modules/home/configs/ai/pi/unipi-footer-autocomplete-overlay.patch
          piPatchUnipiFooterAutocomplete = lib.hm.dag.entryAfter ["piPatchUnipiFooter"] ''
            _d="${piPath}/npm/node_modules/@pi-unipi/footer"
            _p=${./pi/unipi-footer-autocomplete-overlay.patch}
            _patch=${lib.getExe pkgs.gnupatch}

            if [ -f "$_d/src/glance-editor.ts" ] && ! $_patch -d "$_d" -p1 -R -s -f --dry-run < "$_p" >/dev/null 2>&1; then
              if ! run $_patch -d "$_d" -p1 -N -s --no-backup-if-mismatch -r - < "$_p"; then
                echo "piPatchUnipiFooterAutocomplete: patch did not apply to $_d; autocomplete overlay not applied"
              fi
            fi
          '';

          # pi-glance: fullscreen autocomplete as an overlay above the frame (same
          # approach as the UniPi patch), and allow a 1-row minimum editor height.
          # Regenerate by diffing a patched copy of the installed package:
          #   git diff -- src/surface/editor.ts > pi/pi-glance-autocomplete-overlay.patch
          #   git diff -- src/config/model.ts src/surface/frame.ts src/settings/catalog.ts > pi/pi-glance-min-rows.patch
          piPatchPiGlance = lib.hm.dag.entryAfter ["piUpdateExtensions"] ''
            _d="${piPath}/npm/node_modules/pi-glance"
            _patch=${lib.getExe pkgs.gnupatch}

            if [ -d "$_d/src" ]; then
              for _p in ${./pi/pi-glance-autocomplete-overlay.patch} ${./pi/pi-glance-min-rows.patch}; do
                if ! $_patch -d "$_d" -p1 -R -s -f --dry-run < "$_p" >/dev/null 2>&1; then
                  if ! run $_patch -d "$_d" -p1 -N -s --no-backup-if-mismatch -r - < "$_p"; then
                    echo "piPatchPiGlance: $_p did not apply to $_d"
                  fi
                fi
              done
            fi
          '';
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
              PI_CODING_AGENT_DIR = piPath;
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
                # "npm:pi-agent-browser-native"
                # "npm:pi-autoresearch"
                # "npm:pi-blackhole"
                "npm:pi-codemode-toggle"
                "npm:pi-context-view"
                "npm:pi-hashline-edit"
                # "npm:pi-mcp-adapter"
                # "npm:pi-powerline-footer"
                "npm:@optomatica/pi-auto-session-name"
                "npm:pi-tool-display" # https://github.com/MasuRii/pi-tool-display
                "npm:@pi-unipi/ask-user"
                "npm:@pi-unipi/background-tasks"
                "npm:@pi-unipi/btw"
                "npm:@pi-unipi/compactor"
                "npm:@pi-unipi/footer"
                "npm:@pi-unipi/memory"
                "npm:@pi-unipi/milestone"
                "npm:@pi-unipi/notify"
                "npm:@pi-unipi/subagents"
                "npm:@pi-unipi/workflow"
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
