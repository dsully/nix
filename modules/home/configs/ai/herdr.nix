{
  config,
  lib,
  my,
  pkgs,
  ...
}: let
  cfg = config.programs.herdr;

  herdr = cfg.package;

  enabledPlugins = lib.filterAttrs (_: p: p.enable) cfg.plugins;

  # Plugin build commands are ordinary shell commands run by `herdr plugin
  # install`, so every toolchain they call must be on PATH. Home Manager's
  # activation PATH has none of them. Only the enabled plugins contribute, so a
  # disabled plugin costs nothing: herdr itself needs none of this.
  buildPath = lib.makeBinPath (
    lib.unique (
      # gawk and gnused earn their place: plugin build scripts reach for them to
      # parse versions and verify checksums, and a missing one does not fail
      # loudly — it makes the script take a slower fallback path.
      (with pkgs; [
        cacert
        coreutils
        curl
        gawk
        git
        gnugrep
        gnused
        gnutar
        gzip
        unzip
      ])
      ++ lib.concatMap (p: p.buildInputs) (lib.attrValues enabledPlugins)
    )
  );

  pluginType = lib.types.submodule ({name, ...}: {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to install this Herdr plugin during activation.";
      };

      id = lib.mkOption {
        type = lib.types.str;
        default = name;
        description = "Plugin ID as reported by `herdr plugin list`.";
      };

      source = lib.mkOption {
        type = lib.types.str;
        description = "GitHub source in `owner/repo[/subdir]` form.";
      };

      ref = lib.mkOption {
        type = lib.types.str;
        description = "Git revision to pin the plugin checkout to.";
      };

      buildInputs = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [];
        description = ''
          Toolchains this plugin's `[[build]]` command needs. They go on the
          PATH of `herdr-sync` only, never into the home profile.
        '';
      };

      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [];
        description = ''
          Runtime dependencies added to `home.packages` when this plugin is
          enabled. Plugin commands run from the Herdr server, so they see the
          normal user PATH rather than the build PATH.
        '';
      };
    };
  });

  pluginInstallLines =
    lib.concatMapStringsSep "\n"
    (p: "install_plugin ${lib.escapeShellArgs [p.id p.source p.ref]}")
    (lib.attrValues enabledPlugins);

  integrationLines =
    lib.concatMapStringsSep "\n"
    (target: "install_integration ${lib.escapeShellArg target}")
    cfg.integrations;

  localPluginLines =
    lib.concatMapStringsSep "\n"
    (p: "link_plugin ${lib.escapeShellArg "${p}"}")
    cfg.localPlugins;

  # Also exposed as a command so plugin and integration drift can be repaired without a full home-manager activation.
  sync = pkgs.writeShellApplication {
    name = "herdr-sync";
    runtimeInputs = [herdr pkgs.jq];
    text = ''
      # /usr/bin last: only Xcode's swiftc (herdr-prompt-reply) needs it, and it
      # must not shadow a nixpkgs tool of the same name.
      export PATH="${buildPath}:$PATH:/usr/bin"

      ${lib.optionalString config.programs.claude-code.enable ''
        export CLAUDE_CONFIG_DIR=${lib.escapeShellArg config.programs.claude-code.configDir}
      ''}

      install_integration() {
          # Non-fatal: an agent whose config directory does not exist yet is a
          # normal state, not an activation failure.
          herdr integration install "$1" || echo "herdr-sync: integration $1 failed" >&2
      }

      link_plugin() {
          # Registers a plugin that already exists in the store: `link` reads
          # the manifest and runs no build command. Re-linking the same root is
          # a no-op, and the store path changes on every package rebuild, so
          # this runs unconditionally rather than comparing roots.
          herdr plugin link "$1" >/dev/null ||
              echo "herdr-sync: local plugin $1 failed to link" >&2
      }

      install_plugin() {
          local id="$1" source="$2" ref="$3"

          if printf '%s\n' "$installed" | grep -qxF "$id"; then
              return 0
          fi

          echo "herdr-sync: installing plugin $id ($source@$ref)"

          # Plugin builds fetch and compile from GitHub. Let one failure report
          # itself and continue rather than abort activation.
          herdr plugin install "$source" --ref "$ref" --yes ||
              echo "herdr-sync: plugin $id failed to install" >&2
      }

      ${integrationLines}

      ${localPluginLines}

      # `|| true` keeps an unreachable registry from aborting the whole sync;
      # an empty list just means every plugin is treated as missing.
      installed="$(herdr plugin list --json | jq -r '.result.plugins[]?.plugin_id' || true)"

      ${pluginInstallLines}
    '';
  };
in {
  options.programs.herdr = {
    integrations = lib.mkOption {
      type = lib.types.listOf (lib.types.enum [
        "claude"
        "codex"
        "opencode"
        "pi"
      ]);
      default = ["claude" "opencode"];
      description = ''
        Agents to install the Herdr integration for. The integration reports
        session identity (Claude Code, Codex) or full lifecycle state (OpenCode,
        pi) to the Herdr server, which is what drives the agent sidebar.
      '';
    };

    plugins = lib.mkOption {
      type = lib.types.attrsOf pluginType;
      default = {};
      description = "Herdr plugins installed from GitHub at a pinned revision.";
    };

    localPlugins = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = ''
        Packages holding a `herdr-plugin.toml` at their root, registered with
        `herdr plugin link`. Use this for plugins built by this flake: Nix has
        already built them, so the manifest's build command must not run.
      '';
    };
  };

  config = lib.mkMerge [
    {
      programs.herdr = {
        enable = lib.mkDefault true;
        package = pkgs.llm-agents.herdr;

        # Built by this flake, so they are linked rather than installed. Their
        # metadata feeds the `$icon` and `$last` sidebar tokens below.
        localPlugins = with my.pkgs; [
          herdr-autoname
          herdr-recall
        ];

        plugins = {
          # Opens files and URLs already printed on the pane's screen. Its build
          # command only checks that Television 0.15+ is on PATH.
          # termscope = {
          #   source = "iurysza/termscope";
          #   ref = "328a777796e3e1a214da1bb6da79e4bfdf6dfabe";
          #   buildInputs = [pkgs.television];
          #   packages = with pkgs; [python3 television];
          # };

          # Names workspaces and tabs from their content. Off by default: it
          # runs a worker that calls an LLM provider you must configure first
          # (`herdr plugin action invoke tab-smart-rename.setup`).
          tab-smart-rename = {
            source = "iurysza/herdr-tab-smart-rename";
            ref = "58c424c37c6966da060da1bd724d8d6cee8126af";
            buildInputs = [pkgs.bun];
            packages = [pkgs.bun];
          };

          # Answers agent permission prompts from a macOS notification. Off by
          # default: the build needs swiftc from the Xcode command line tools.
          "cedrus.prompt-reply" = {
            source = "cedrus-8864/herdr-prompt-reply";
            ref = "e34e7d0040d910dac0218745462a7e0e4cc66f1b";
          };

          # Fuzzy jump to any workspace, agent, or session. Off by default: it
          # overlaps Herdr's own prefix+g navigator and prefix+w picker.
          # herdr-navigator = {
          #   source = "thanhdat77/herdr-navigator";
          #   ref = "9bdf30f03f53730e6232377a3fca3bdc6ed9f3ca";
          #   buildInputs = with pkgs; [cargo rustc];
          # };
        };

        settings = {
          # Keeps recent pane output readable after a server restart, which is
          # what makes detaching from a long agent run safe.
          experimental.pane_history = true;

          keys = {
            command = [
              {
                key = "prefix+alt+g";
                type = "popup";
                command = lib.getExe pkgs.gitui;
                width = "80%";
                height = "80%";
              }
              {
                key = "prefix+alt+r";
                type = "popup";
                command = "${lib.getExe my.pkgs.herdr-recall} show | ${lib.getExe' pkgs.less "less"} -R";
                description = "what each pane was running";
                width = "80%";
                height = "60%";
              }
            ];

            rename_tab = "prefix+comma";
          };

          onboarding = false;

          terminal = {
            default_shell = lib.getExe pkgs.fish;
            shell_mode = "auto";
            new_cwd = "follow";
          };

          theme.name = "nord";

          ui = {
            # Sort by attention needed, so blocked agents come first.
            agent_panel_sort = "priority";

            sidebar = {
              agents.rows_by_agent = builtins.listToAttrs (
                map (agent: {
                  name = agent;
                  value = [
                    ["state_icon" "$icon" "state_text"]
                    ["terminal_title_stripped"]
                    ["workspace" "tab"]
                  ];
                }) [
                  "claude"
                  "codex"
                  "opencode"
                  "pi"
                ]
              );

              # `$icon` comes from herdr-autoname's reported metadata, `$last`
              # from herdr-recall's. Agent rows carry the terminal title
              # already, so only the plain-pane rows show the last command.
              agents.rows = [
                ["state_icon" "$icon" "state_text"]
                ["terminal_title_stripped"]
                ["$last"]
              ];

              spaces.rows = [
                ["state_icon" "$icon" "workspace"]
                ["branch" "git_status"]
              ];
            };

            sound.enabled = true;
            status_indicators = "symbols";

            toast.delivery = "system";
            window_title = "{hostname}: {workspace}";
          };

          update = {
            # Nix owns the version; herdr disables its own self-update for
            # /nix/store installs anyway. Detection manifests are data, not
            # code, and keep agent state recognition current between bumps.
            version_check = false;
            manifest_check = true;
          };

          worktrees.directory = "~/.herdr/worktrees";
        };
      };
    }

    (lib.mkIf cfg.enable {
      home = {
        # herdr-autoname is driven entirely by herdr through its plugin root,
        # so only recall — whose `show` output is worth reading by hand — earns
        # a place in the profile.
        packages =
          [sync my.pkgs.herdr-recall]
          ++ lib.concatMap (p: p.packages) (lib.attrValues enabledPlugins);

        # linkGeneration first: `integration install` refuses to run until the
        # agent's config directory exists.
        activation.herdrSync = lib.hm.dag.entryAfter ["linkGeneration"] ''
          $DRY_RUN_CMD ${lib.getExe sync} || true
        '';
      };

      programs = {
        # `herdr --skill` is the upstream-maintained guide for driving panes,
        # agents, and workspaces from inside a Herdr pane. Its description gates
        # itself on HERDR_ENV, so it costs nothing outside Herdr.
        ai.skills.herdr = {
          path = pkgs.runCommand "herdr-skills" {} ''
            mkdir -p $out/herdr
            ${lib.getExe herdr} --skill > $out/herdr/SKILL.md
          '';
          ids = ["herdr"];
        };

        # Both hooks report per-command state that no herdr event can supply:
        # herdr has no "foreground command changed" event. Each file no-ops
        # outside a herdr pane, so this is safe in every shell.
        fish.interactiveShellInit = lib.mkAfter ''
          source ${my.pkgs.herdr-autoname}/shell/hook.fish
          source ${my.pkgs.herdr-recall}/shell/hook.fish
        '';

        fish.functions = {
          hws = {
            description = "Create or focus a Herdr space for the current git repo";
            body =
              # fish
              ''
                if test "$HERDR_ENV" != 1
                    echo "hws: not inside a Herdr pane" >&2
                    return 1
                end

                set -l root (${lib.getExe pkgs.git} rev-parse --show-toplevel 2>/dev/null; or echo $PWD)
                set -l label (path basename $root)

                set -l existing (herdr workspace list |
                    ${lib.getExe pkgs.jq} -r --arg l $label \
                        '.result.workspaces[] | select(.label == $l) | .workspace_id')

                if test -n "$existing"
                    herdr workspace focus $existing[1] >/dev/null
                    return
                end

                herdr workspace create --cwd $root --label $label --focus >/dev/null
              '';
          };

          hagent = {
            description = "Split the current pane and start a named Herdr agent in it";
            body =
              # fish
              ''
                if test "$HERDR_ENV" != 1
                    echo "hagent: not inside a Herdr pane" >&2
                    return 1
                end

                set -l name $argv[1]
                set -l kind $argv[2]

                if test -z "$name"
                    echo "usage: hagent <name> [kind] [prompt]" >&2
                    return 1
                end

                test -n "$kind"; or set kind claude

                set -l pane (herdr pane split --current --direction right --no-focus |
                    ${lib.getExe pkgs.jq} -r '.result.pane.pane_id')

                herdr agent start $name --kind $kind --pane $pane >/dev/null

                if test (count $argv) -gt 2
                    herdr agent prompt $name (string join " " $argv[3..])
                end
              '';
          };

          hwt = {
            description = "Open a Herdr space on a git worktree for the given branch";
            body =
              # fish
              ''
                if test "$HERDR_ENV" != 1
                    echo "hwt: not inside a Herdr pane" >&2
                    return 1
                end

                set -l branch $argv[1]

                if test -z "$branch"
                    echo "usage: hwt <branch> [base-ref]" >&2
                    return 1
                end

                set -l base $argv[2]

                if test -n "$base"
                    herdr worktree create --cwd $PWD --branch $branch --base $base --focus
                else
                    herdr worktree create --cwd $PWD --branch $branch --focus
                end
              '';
          };
        };
      };
    })
  ];
}
