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
  piCompiledBase = "${config.xdg.dataHome}/pi-bolt";

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

  piDefaultPackages = lib.unique [
    # The extension injects core ponytail from its SKILL.md path; audit + review come
    # hidden from agent-skills below, reachable through its /ponytail-* aliases.
    {
      source = "npm:@dietrichgebert/ponytail";
      skills = [];
    }
    # "npm:@ff-labs/pi-fff"
    # Installed but loads nothing: its 11 UI tools cost ~3k prompt tokens every turn.
    # Enable per repo with the `pi-computer-use` fish function, which adds an
    # autoload=false delta to <repo>/.pi/settings.json that reuses this install.
    {
      source = "npm:@injaneity/pi-computer-use";
      extensions = [];
    }
    # "npm:pi-agent-browser-native"
    # Its tools stay inactive until `/autoresearch <goal>`; `/autoresearch off` removes them.
    "npm:pi-autoresearch"
    "npm:pi-away"
    "npm:pi-context-view"
    "npm:pi-hashline-edit-pro-lean"
    "npm:pi-heads-up"
    # "npm:@pi-kaush/pi-browser"
    "npm:@cortexkit/pi-magic-context"
    # Snapshots per turn: hashline replace/insert carry no path, so edit/write-hooked checkpointers miss them.
    "npm:pi-rewind-hook"
    "npm:@ssk_dev/pi-docs-slim"
    "npm:@ssk_dev/pi-subagents-lean"
    "npm:@ssk_dev/rpiv-ask-user-question-lean"
    "npm:@vanillagreen/pi-session-manager"
  ];

  # Package entries may be a source string or an attrset with one; other modules
  # append to settings.packages, so read the merged option, not piDefaultPackages.
  declaredPackageSources = map (p:
    if builtins.isString p
    then p
    else p.source)
  config.programs.pi-coding-agent.settings.packages;

  piNpmDependencies = lib.listToAttrs (map (src: let
    m = builtins.match "npm:(@?[^@]+)(@(.+))?" src;
  in
    lib.nameValuePair (builtins.elemAt m 0) (
      if builtins.elemAt m 2 == null
      then "latest"
      else builtins.elemAt m 2
    )) (lib.filter (lib.hasPrefix "npm:") declaredPackageSources));

  # Nix owns the whole file; bun.lock holds the resolved versions behind "latest".
  piNpmPackageJson = jsonFormat.generate "pi-npm-package.json" ({
      name = "pi-extensions";
      private = true;
      dependencies = piNpmDependencies;
    }
    // lib.optionalAttrs (config.programs.pi-coding-agent.npmOverrides != {}) {
      overrides = config.programs.pi-coding-agent.npmOverrides;
    }
    // lib.optionalAttrs (config.programs.pi-coding-agent.npmTrustedDependencies != []) {
      trustedDependencies = config.programs.pi-coding-agent.npmTrustedDependencies;
    });

  piExtensions =
    lib.filterAttrs (
      name: type:
        (type == "directory" || type == "regular" && lib.hasSuffix ".ts" name)
        && !lib.elem name config.programs.pi-coding-agent.excludeExtensions
    )
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

    paths = [config.programs.bun.package];

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

      excludeExtensions = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        example = ["todo" "history.ts"];
        description = "Entries under dotfiles/pi/extensions (directory or .ts file name) not linked into pi.";
      };

      mcpDescriptions = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = "Per-server one-line descriptions listed in pi's system prompt, replacing the server's own instructions.";
      };

      extensionPatches = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            pkg = lib.mkOption {
              type = lib.types.str;
              description = "Package name under pi's npm/node_modules.";
            };
            patch = lib.mkOption {
              type = lib.types.path;
              description = "Patch applied with -p1 from the package root.";
            };
          };
        });
        default = [];
        description = "Patches applied to installed pi npm packages after each install.";
      };

      npmOverrides = lib.mkOption {
        inherit (jsonFormat) type;
        default = {};
        description = "`overrides` of pi's npm/package.json.";
      };

      npmTrustedDependencies = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Packages whose lifecycle scripts bun runs; bun's own default list (esbuild, ...) still applies.";
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

              # pi has no path-scoped rules; extensions/skills-manager registers the matching ones as skills per repo.
              "${piPath}/rules-skills".source = rulesSkills;

              "${piPath}/mcp.json".source = jsonFormat.generate "pi-mcp.json" {
                mcpServers = piMcpServers;
              };

              # Mechanical delegation runs on Sonnet per AGENTS.md. Frontmatter outranks a caller's model param.
              "${piPath}/agents/general-purpose.md" = {
                text = ''
                  ---
                  description: General-purpose agent for researching complex questions, searching for code, and executing multi-step tasks. When you are searching for a keyword or file and are not confident that you will find the right match in the first few tries use this agent to perform the search for you.
                  model: ${config.programs.pi-coding-agent.settings.defaultProvider}/${ai.models.medium.model}
                  thinking: ${ai.models.medium.reasoning_effort}
                  prompt_mode: append
                  ---
                '';
              };

              "${config.xdg.configHome}/cortexkit/magic-context.jsonc".source = jsonFormat.generate "magic-context.jsonc" config.programs.pi-coding-agent.magicContext;
            };

          activation = {
            # Removing a package from Nix is not enough: pi's mutable settings.json
            # keeps the entry, and pi reinstalls it at startup. Diff the declared list
            # against the copy the last activation wrote, and let `pi remove` drop it.
            # Then write npm/package.json; `bun install` prunes what it no longer lists.
            # Retry a few times to ride out transient registry failures.
            # Non-fatal: a persistent failure warns, never aborts the switch.
            piUpdateExtensions = lib.hm.dag.entryAfter ["onFilesChange" "piCodingAgentMutableSettings"] ''
              export PATH="${lib.makeBinPath [bunRuntime pkgs.diffutils pkgs.git pkgs.gnugrep pkgs.jq]}:$PATH"
              export PI_CODING_AGENT_DIR="${piPath}"

              _state="${piPath}/.nix-packages"
              _cur=${lib.escapeShellArg (lib.concatStringsSep "\n" declaredPackageSources)}

              _stale=0
              if [[ -f $_state && ! -v DRY_RUN ]]; then
                while IFS= read -r _src; do
                  [[ -n $_src ]] || continue

                  grep -qxF -- "$_src" <<< "$_cur" && continue

                  # `pi remove` exits 1 for an entry settings.json no longer lists, which would pin it here forever.
                  jq -e --arg s "$_src" 'any(.packages[]?; (.source? // .) == $s)' "${piPath}/settings.json" >/dev/null 2>&1 || continue

                  run ${config.programs.pi-coding-agent.package}/bin/pi remove "$_src" </dev/null || {
                    echo "pi remove $_src failed; keeping it in $_state to retry"
                    _stale=1
                  }

                done < "$_state"
              fi

              _npm="${piPath}/npm"
              cmp -s ${piNpmPackageJson} "$_npm/package.json" || run install -D -m644 ${piNpmPackageJson} "$_npm/package.json"

              _ok=
              for _try in 1 2 3; do
                if run bun install --cwd "$_npm" --omit=peer; then
                  _ok=1
                  break
                fi

                echo "bun install attempt $_try failed; retrying in 5s..."
                sleep 5
              done

              [ -n "$_ok" ] || echo "bun install in $_npm failed after 3 tries; run it manually to see errors"

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
                '')
                config.programs.pi-coding-agent.extensionPatches}
            '';

            # AOT-compile the installed extensions into a pi-bolt build the package wrapper prefers.
            # `pi compile` refuses PIBOLT_NPM and a read-only tree, so it runs from a writable copy.
            # Non-fatal: a failure keeps the previous build, or the store binary once .nix-source mismatches.
            piCompileExtensions = lib.hm.dag.entryAfter ["piPatchExtensions"] ''
              if [[ ! -v DRY_RUN ]]; then
                _base=${lib.escapeShellArg piCompiledBase}
                _pkg=${my.pkgs.pi-bolt}
                _src="$_base/src"
                mkdir -p "$_base"

                if ! { read -r _s < "$_src/.nix-source"; } 2>/dev/null || [[ $_s != "$_pkg" ]]; then
                  [[ -d $_src ]] && chmod -R u+w "$_src" && rm -rf "$_src"
                  cp -R "$_pkg/libexec/pi" "$_src" && chmod -R u+w "$_src" && echo "$_pkg" > "$_src/.nix-source"
                fi

                rm -rf "$_base/next"

                if env -u PIBOLT_NPM PATH="${lib.makeBinPath [pkgs.gnutar pkgs.gzip]}:$PATH" PI_PACKAGE_DIR="$_src" PI_CODING_AGENT_DIR="${piPath}" "$_src/pi" compile --kit ${my.pkgs.pi-bolt-kit}/archive.tar.gz --runtime ${my.pkgs.pi-bolt-runtime}/archive.tar.gz --out "$_base/next"; then

                  echo "$_pkg" > "$_base/next/.nix-source"
                  _new="$_base/build-$(date +%s)"

                  mv "$_base/next" "$_new"

                  _prev=$(readlink "$_base/current" || true)

                  ln -sfn "$_new" "$_base/current"

                  for _b in "$_base"/build-*; do
                    [[ $_b == "$_new" || $_b == "$_prev" ]] || rm -rf "$_b"
                  done

                else
                  echo "pi compile failed; see $_base/next.compile.log. pi keeps the previous build or the store binary."
                fi
              fi
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
                FFF_ENABLE_HOME_SCAN = "0";
                # No editor can open inside pi's bash tool; git would block on it.
                GIT_EDITOR = "true";
                GIT_SEQUENCE_EDITOR = "true";
                PIBOLT_COMPILED_DIR = "${piCompiledBase}/current";
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

            # Its postinstall installs the macOS helper app.
            npmTrustedDependencies = lib.optional (piNpmDependencies ? "@injaneity/pi-computer-use") "@injaneity/pi-computer-use";

            extensionPatches = [
              {
                pkg = "pi-hashline-edit-pro-lean";
                patch = ./pi-hashline-lean-edit-output-schema.patch;
              }
              {
                pkg = "@cortexkit/pi-magic-context";
                patch = ./pi-magic-context-status-active-tool-defs.patch;
              }
              {
                pkg = "@cortexkit/pi-magic-context";
                patch = ./pi-magic-context-drop-omp-loader.patch;
              }
              {
                pkg = "@juicesharp/rpiv-ask-user-question";
                patch = ./pi-ask-user-question-blocked-status.patch;
              }
            ];
            # pi writes settings.json itself (model, theme, `pi install`); Nix values win on each switch.
            mutableSettings = true;

            magicContext = {
              # Keep the 1M window as headroom, but reduce as if it were ~250K.
              execute_threshold_tokens."${ai.models.large.provider}/${ai.models.large.model}" = lib.mkDefault 250000;

              historian.pi.model = lib.mkDefault "${ai.models.small.provider}/${ai.models.small.model}";
            };

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
              outputPad = 0;

              hooks = ai.hooks.pi;
              quietStartup = true;
              skipApprovals = true;

              steeringMode = "all";
              followUpMode = "all";

              npmCommand = [(lib.getExe bunRuntime)];

              packages = lib.filter (p: !lib.elem (p.source or p) config.programs.pi-coding-agent.excludePackages) piDefaultPackages;

              rewind.retention.maxAgeDays = 7;

              shadedCodeBlocks = true;

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
