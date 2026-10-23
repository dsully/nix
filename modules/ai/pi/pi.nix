{
  mkUserModule,
  ai,
  config,
  hideFromModel,
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
  piMcpServers = lib.mapAttrs (name: server:
    lib.hm.mcp.transformMcpServer {inherit server;}
    // {exposure = "deferred";}
    // lib.optionalAttrs (server.enabled == false) {disabled = true;}
    // lib.optionalAttrs (config.programs.pi-coding-agent.mcpDescriptions ? ${name}) {
      description = config.programs.pi-coding-agent.mcpDescriptions.${name};
    })
  config.programs.mcp.servers;

  # tintinweb/pi-subagents and teelicht/pi-superagents both own
  # extensions/subagent/; install exactly one. Superpowers integrates with the
  # teelicht fork, so track its enable state for pi.
  piSuperpowers = lib.elem "pi" config.programs.ai.superpowers.agents;

  piDefaultPackages = lib.unique (
    [
      # "npm:context-mode"
      # The extension injects core ponytail from its SKILL.md path; audit + review come
      # hidden from agent-skills below, reachable through its /ponytail-* aliases.
      {
        source = "npm:@dietrichgebert/ponytail";
        skills = [];
      }
      # "git:github.com/light4/pi-session-manager@v0.2.16"
      "npm:@ff-labs/pi-fff"
      # Installed but loads nothing: its 11 UI tools cost ~3k prompt tokens every turn.
      # Enable per repo with the `pi-computer-use` fish function, which adds an
      # autoload=false delta to <repo>/.pi/settings.json that reuses this install.
      {
        source = "npm:@injaneity/pi-computer-use";
        extensions = [];
      }
      "npm:@optomatica/pi-auto-session-name"
      # "npm:pi-agent-browser-native"
      # "npm:pi-autoresearch"
      # "npm:pi-blackhole"
      "npm:pi-away"
      "npm:pi-background"
      "npm:pi-checkpoints"
      "npm:pi-codemode-toggle"
      "npm:pi-context-view"
      "npm:pi-hashline-edit-pro-lean"
      "npm:pi-heads-up"
      "npm:pi-inspector"
      "npm:pi-next-prompt"
      # chrome.ts would take over the working label, spinner, and editor that whimsical and footer own.
      {
        source = "npm:pi-polish";
        extensions = ["extensions/tools.ts"];
      }
      # "npm:pi-resume-search"
      "npm:@pi-unipi/compactor@alpha"
      # Their bundled skills restate the tool descriptions every turn.
      {
        source = "npm:@pi-unipi/memory@alpha";
        skills = [];
      }
      "npm:@ssk_dev/pi-docs-slim"
      "npm:@ssk_dev/rpiv-ask-user-question-lean"
      "npm:@ssk_dev/rpiv-todo-lean"
      "npm:@tifan/pi-copy-response"
      "npm:@vanillagreen/pi-skills-manager"
    ]
    ++ lib.optional (!piSuperpowers) "npm:@ssk_dev/pi-subagents-lean"
    ++ lib.optional piSuperpowers "npm:@teelicht/pi-superagents"
  );

  # Bare npm names, matching the dependency keys pi writes to npm/package.json.
  piNpmNames = lib.concatMap (p: let
    source = p.source or p;
  in
    lib.optional (lib.hasPrefix "npm:" source) (builtins.head (builtins.match "(@?[^@]+).*" (lib.removePrefix "npm:" source))))
  config.programs.pi-coding-agent.settings.packages;

  piMemory = lib.any (p: lib.hasPrefix "npm:@pi-unipi/memory" (p.source or p)) (config.programs.pi-coding-agent.settings.packages or []);

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

    homeOptions.programs.pi-coding-agent = {
      excludePackages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Package sources removed from the default pi packages list.";
      };

      mcpDescriptions = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = "Per-server one-line descriptions listed in pi's system prompt, replacing the server's own instructions.";
      };
    };

    home = lib.mkMerge [
      (import ./theme.nix {inherit config lib pkgs piPath;}).config
      {
        _module.args.piPath = piPath;
        programs.pi-coding-agent.enable = lib.mkDefault true;
      }

      (lib.mkIf config.programs.pi-coding-agent.enable {

        warnings =
          map (p: "programs.pi-coding-agent.excludePackages: \"${p}\" matches no default pi package source.")
          (lib.subtractLists (map (p: p.source or p) piDefaultPackages) config.programs.pi-coding-agent.excludePackages);

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

              # pi has no path-scoped rules; extensions/rules-skills registers the matching ones as skills per repo.
              "${piPath}/rules-skills".source = rulesSkills;

              "${piPath}/mcp.json".source = jsonFormat.generate "pi-mcp.json" {
                mcpServers = piMcpServers;
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
            }
            # The wake-up block is truncated memory-file snippets; the reminder and memory_search stay.
            // lib.optionalAttrs piMemory {
              ".unipi/config/memory/config.json".source = jsonFormat.generate "unipi-memory-config.json" {
                recall = "reminder";
              };
            };

          activation = {
            # pi-superagents reads ~/.pi/agent/extensions/subagent/config.json (~/.pi links to piPath's parent)
            # and rewrites it with new bundled defaults, so merge into a writable file instead of a store symlink.
            # Its bundled tiers point at opencode-go/openai models; cheap runs sp-implementer, so Sonnet per AGENTS.md.
            piSuperagentsConfig = lib.mkIf piSuperpowers (lib.hm.dag.entryAfter ["writeBoundary"] ''
              _cfg="${piPath}/extensions/subagent/config.json"
              if [[ ! -v DRY_RUN ]]; then
                mkdir -p "''${_cfg%/*}"
                [[ -f $_cfg ]] || echo '{}' > "$_cfg"
                ${lib.getExe pkgs.jq} -s '.[0] * .[1]' "$_cfg" ${jsonFormat.generate "pi-superagents-config.json" {
                superagents.modelTiers = {
                  cheap.model = "claude-sonnet-5-5";
                  balanced = {
                    model = "claude-sonnet-5-5";
                    thinking = "high";
                  };
                  max = {
                    model = "claude-opus-5-5";
                    thinking = "high";
                  };
                };
              }} > "$_cfg.tmp" && mv "$_cfg.tmp" "$_cfg"
              fi
            '');
            # Install/update the extensions listed in settings.json once
            # onFilesChange has written it. pi adds npm dependencies on install
            # but never drops removed ones (nor does bun delete their node_modules
            # dirs), so prune both first.
            # Retry a few times to ride out transient registry failures.
            # Non-fatal: a persistent failure warns, never aborts the switch.
            piUpdateExtensions = lib.hm.dag.entryAfter ["onFilesChange"] ''
              export PATH="${lib.makeBinPath [config.programs.bun.package pkgs.git]}:$PATH"
              export PI_CODING_AGENT_DIR="${piPath}"
              _ok=
              _pkg="${piPath}/npm/package.json"

              if [[ -f $_pkg && ! -v DRY_RUN ]]; then
                _keep='${builtins.toJSON piNpmNames}'

                for _dep in $(${lib.getExe pkgs.jq} -r --argjson keep "$_keep" '.dependencies // {} | keys[] | select(. as $k | $keep | index($k) | not)' "$_pkg"); do
                  rm -rf "${piPath}/npm/node_modules/$_dep"
                done

                ${lib.getExe pkgs.jq} --argjson keep "$_keep" \
                  '.dependencies |= ((. // {}) | with_entries(select(.key as $k | $keep | index($k))))' \
                  "$_pkg" > "$_pkg.tmp" && mv "$_pkg.tmp" "$_pkg"
              fi

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

            # Reverse dry-run detects an already-patched tree.
            piPatchExtensions = lib.hm.dag.entryAfter ["piUpdateExtensions"] ''
              _patch=${lib.getExe pkgs.gnupatch}
              ${lib.concatMapStrings ({
                  pkg,
                  patch,
                }: ''
                  _d="${piPath}/npm/node_modules/${pkg}"
                  if [ -d "$_d" ] && ! $_patch -d "$_d" -p1 -R -s -f --dry-run < ${patch} >/dev/null 2>&1; then
                    if ! run $_patch -d "$_d" -p1 -N -s --no-backup-if-mismatch -r - < ${patch}; then
                      echo "piPatchExtensions: ${baseNameOf patch} did not apply to $_d"
                    fi
                  fi
                '') [
                  # before_agent_start from sendCustomMessage has no prompt; upstream crashes on it.
                  {
                    pkg = "@teelicht/pi-superagents";
                    patch = ./pi-superagents-prompt-undefined.patch;
                  }
                  # Task items repeat the top-level field descriptions.
                  {
                    pkg = "@teelicht/pi-superagents";
                    patch = ./pi-superagents-task-schema.patch;
                  }
                  {
                    pkg = "pi-hashline-edit-pro-lean";
                    patch = ./pi-hashline-lean-edit-output-schema.patch;
                  }
                ]}
            '';

            # mempalace breaks on Python 3.15; uv records --python in the tool
            # receipt, so uvTool's later install/upgrade keep this interpreter.
            mempalacePython = lib.mkIf piMemory (lib.hm.dag.entryBetween ["uvTool"] ["linkGeneration"] ''
              run ${lib.getExe config.programs.uv.package} tool install $VERBOSE_ARG --python 3.14 mempalace
            '');
          };
        };

        programs = {
          agent-skills = {
            targets.pi.enable = true;
            sources.ponytail = {
              input = "ponytail";
              subdir = "skills";
            };
            # pi-only: Claude Code gets these from the ponytail plugin.
            skills.explicit = lib.genAttrs ["ponytail-audit" "ponytail-review"] (id: {
              from = "ponytail";
              path = id;
              agents = ["pi"];
              transform = hideFromModel;
            });
          };
          ai.superpowers.agents = ["pi"];

          pi-coding-agent = {
            package = wrapperLib.wrapPackage {
              inherit pkgs;
              package = my.pkgs.pi-bolt;

              envDefault = {
                FFF_ENABLE_HOME_SCAN = "0";
                PI_CLIPBOARD_OSC52 = "1";
                PI_CODING_AGENT_DIR = piPath;
                PI_COMPUTER_USE_BROWSER_USE = "1";
                PI_COMPUTER_USE_CDP_PORT = "9222";
                PI_COMPUTER_USE_MANAGED_BROWSER = "chrome";
                PI_SKIP_VERSION_CHECK = "1";
                PI_TELEMETRY = "0";
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

              packages = lib.filter (p: !lib.elem (p.source or p) config.programs.pi-coding-agent.excludePackages) piDefaultPackages;

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
