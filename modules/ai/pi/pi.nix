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
  # and empty-default fields. Exposure stays at pi's default "codemode": "deferred"
  # tools loaded by tool_search change the declared tool list and reset the prompt cache.
  piMcpServers = lib.mapAttrs (name: server:
    lib.hm.mcp.transformMcpServer {inherit server;}
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
      # The extension injects core ponytail from its SKILL.md path; audit + review come
      # hidden from agent-skills below, reachable through its /ponytail-* aliases.
      {
        source = "npm:@dietrichgebert/ponytail";
        skills = [];
      }
      "npm:@ff-labs/pi-fff"
      # Installed but loads nothing: its 11 UI tools cost ~3k prompt tokens every turn.
      # Enable per repo with the `pi-computer-use` fish function, which adds an
      # autoload=false delta to <repo>/.pi/settings.json that reuses this install.
      {
        source = "npm:@injaneity/pi-computer-use";
        extensions = [];
      }
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
      # chrome.ts would take over the working label, spinner, and editor that whimsical and footer own.
      {
        source = "npm:pi-polish";
        extensions = ["extensions/tools.ts"];
      }
      # "npm:pi-resume-search"
      "npm:@cortexkit/pi-magic-context"
      "npm:@ssk_dev/pi-docs-slim"
      "npm:@ssk_dev/rpiv-ask-user-question-lean"
      "npm:@tifan/pi-copy-response"
      "npm:@vanillagreen/pi-session-manager"
    ]
    ++ lib.optional (!piSuperpowers) "npm:@ssk_dev/pi-subagents-lean"
    ++ lib.optional piSuperpowers "npm:@teelicht/pi-superagents"
  );

  # Package entries may be a source string or an attrset with one; other modules
  # (gortex) append to settings.packages, so read the merged option, not piDefaultPackages.
  declaredPackageSources = map (p:
    if builtins.isString p
    then p
    else p.source)
  config.programs.pi-coding-agent.settings.packages;

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

      magicContext = lib.mkOption {
        inherit (jsonFormat) type;
        default = {};
        description = "Contents of ~/.config/cortexkit/magic-context.jsonc.";
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

              # Mechanical delegation runs on Sonnet per AGENTS.md. Frontmatter outranks a caller's model param.
              "${piPath}/agents/general-purpose.md" = lib.mkIf (!piSuperpowers) {
                text = ''
                  ---
                  description: General-purpose agent for researching complex questions, searching for code, and executing multi-step tasks. When you are searching for a keyword or file and are not confident that you will find the right match in the first few tries use this agent to perform the search for you.
                  model: ${config.programs.pi-coding-agent.settings.defaultProvider}/${ai.models.medium.model}
                  thinking: ${ai.models.medium.reasoning_effort}
                  prompt_mode: append
                  ---
                '';
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
              "${config.xdg.configHome}/cortexkit/magic-context.jsonc".source = jsonFormat.generate "magic-context.jsonc" config.programs.pi-coding-agent.magicContext;
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

            # Removing a package from Nix is not enough: pi's mutable settings.json
            # keeps the entry and its npm deps. Diff the declared list against the
            # copy the last activation wrote, and let `pi remove` do the deleting.
            # Retry a few times to ride out transient registry failures.
            # Non-fatal: a persistent failure warns, never aborts the switch.
            piUpdateExtensions = lib.hm.dag.entryAfter ["onFilesChange" "piCodingAgentMutableSettings"] ''
              export PATH="${lib.makeBinPath [config.programs.bun.package pkgs.git pkgs.gnugrep]}:$PATH"
              export PI_CODING_AGENT_DIR="${piPath}"
              _state="${piPath}/.nix-packages"
              _cur=${lib.escapeShellArg (lib.concatStringsSep "\n" declaredPackageSources)}

              _stale=0
              if [[ -f $_state && ! -v DRY_RUN ]]; then
                while IFS= read -r _src; do
                  [[ -n $_src ]] || continue
                  grep -qxF -- "$_src" <<< "$_cur" && continue
                  run ${config.programs.pi-coding-agent.package}/bin/pi remove "$_src" || {
                    echo "pi remove $_src failed; keeping it in $_state to retry"
                    _stale=1
                  }
                done < "$_state"
              fi

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

              # Only advance the baseline once the removals stuck, so a failure is retried on the next switch.
              if [[ ! -v DRY_RUN ]] && [[ -n $_ok ]] && [[ $_stale = 0 ]]; then
                printf '%s\n' "$_cur" > "$_state"
              fi
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
                  {
                    pkg = "pi-gortex";
                    patch = ./pi-gortex-hide-memory-tools.patch;
                  }
                ]}
            '';
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

          fish = {
            functions.pi-bolt = {
              description = "Wrapper around pi-bolt for resume";
              wraps = "pi";
              body = ''
                isatty stdout; and printf '\e]0;%s\a' (path basename $PWD)
                command pi $argv
              '';
            };
          };

          pi-coding-agent = {
            package = wrapperLib.wrapPackage {
              inherit pkgs;
              package = my.pkgs.pi-bolt;
              drv.name = "${my.pkgs.pi-bolt.name}-wrapped";

              envDefault = {
                # No editor can open inside pi's bash tool; git would block on it.
                GIT_EDITOR = "true";
                GIT_SEQUENCE_EDITOR = "true";
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

            # pi writes settings.json itself (model, theme, `pi install`); Nix values win on each switch.
            mutableSettings = true;

            magicContext.historian.pi.model = lib.mkDefault "${ai.models.small.provider}/${ai.models.small.model}";

            # pi has no output styles; append the shared default's body, minus its Claude Code frontmatter.
            context = let
              styleLines = lib.drop 1 (lib.splitString "\n" (builtins.readFile ai.outputStyles.${ai.defaultOutputStyle}));
              body = lib.drop (lib.lists.findFirstIndex (l: l == "---") 0 styleLines + 1) styleLines;
            in ''
              ${builtins.readFile ../shared/AGENTS.md}
              ${lib.trim (lib.concatStringsSep "\n" body)}
            '';

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
                "+grep"
                "+find"
                "+ls"
                "+tool_search"
              ];

              enableInstallTelemetry = false;
              enableSkillCommands = false;

              hideThinkingBlock = true;
              hooks = ai.hooks.pi;
              quietStartup = true;
              skipApprovals = true;

              steeringMode = "all";
              followUpMode = "all";

              npmCommand = [(lib.getExe bunRuntime)];

              packages = lib.filter (p: !lib.elem (p.source or p) config.programs.pi-coding-agent.excludePackages) piDefaultPackages;

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
