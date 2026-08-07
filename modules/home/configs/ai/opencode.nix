{
  ai,
  config,
  inputs,
  lib,
  llmtrimWrap,
  my,
  pkgs,
  ...
}: let
  aro = inputs.autoresearch-opencode;

  lspExtensions = {
    lua = [".lua"];
    nix = [".nix"];
    rust = [".rs"];
    toml = [".toml"];
    typescript = [".ts" ".tsx" ".js" ".jsx"];
  };

  opencodeLsp = lib.mapAttrs (name: v: {
    command = [v.command] ++ (v.args or []);
    extensions = lspExtensions.${name};
  }) (lib.filterAttrs (n: _: lspExtensions ? ${n}) ai.lsp);

  autoresearchSkills = {
    autoresearch = "${aro}/skills/autoresearch";
  };
in {
  # Allow host specific overrides.
  options.programs.opencode.extraPlugins = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    description = "Additional opencode plugins appended to the base set.";
  };

  config = lib.mkMerge [
    {programs.opencode.enable = lib.mkDefault true;}

    (lib.mkIf config.programs.opencode.enable {
      home = {
        # Link the notifier app bundle into ~/Applications and register it with
        # LaunchServices, so notifications are delivered and the app appears in
        # System Settings → Notifications. The plugin launches it from this stable
        # path. (opencode-notifier is emptyFile off darwin.)
        file = lib.mkIf pkgs.stdenv.isDarwin {
          "Applications/OpenCodeNotifier.app".source = "${my.pkgs.opencode-notifier}/Applications/OpenCodeNotifier.app";
        };

        activation.registerOpenCodeNotifierApp = lib.mkIf pkgs.stdenv.isDarwin (
          lib.hm.dag.entryAfter ["linkGeneration"] ''

            lsregister=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

            $DRY_RUN_CMD "$lsregister" -f "$HOME/Applications/OpenCodeNotifier.app"
          ''
        );

        sessionVariables = {
          # https://opencode.ai/docs/cli/#environment-variables
          OPENCODE_DISABLE_AUTOUPDATE = 1;

          # https://opencode.ai/docs/rules/#claude-code-compatibility
          OPENCODE_DISABLE_CLAUDE_CODE = 1;

          OPENCODE_DISABLE_LSP_DOWNLOAD = 1;
          OPENCODE_DISABLE_PRUNE = 1;

          # https://opencode.ai/docs/cli/#experimental
          OPENCODE_EXPERIMENTAL = 1;
          OPENCODE_EXPERIMENTAL_FILEWATCHER = 1;
          OPENCODE_EXPERIMENTAL_ICON_DISCOVERY = 1;
          OPENCODE_EXPERIMENTAL_LSP_TOOL = 1;
          OPENCODE_EXPERIMENTAL_LSP_TY = 1;
          OPENCODE_EXPERIMENTAL_MARKDOWN = 1;
          OPENCODE_EXPERIMENTAL_PLAN_MODE = 1;
        };
      };

      programs = {
        agent-skills.targets.opencode.enable = true;

        # opencode only discovers configs at/below the git worktree root. Walk up
        # from $PWD to $HOME for an opencode.json living above it and inject it.
        fish.functions.opencode = {
          description = "Run opencode with the nearest opencode.json found above the git worktree";
          body =
            # fish
            ''
              set -l dir $PWD
              set -l found_config
              set -l git_root (${lib.getExe pkgs.git} -C $PWD rev-parse --show-toplevel 2>/dev/null)

              while test "$dir" != "$HOME" -a "$dir" != /
                  # Skip dirs inside the worktree — opencode already handles those natively.
                  if test -n "$git_root"; and string match -q -- "$git_root*" $dir
                      set dir (path dirname $dir)
                      continue
                  end

                  if test -f $dir/opencode.json
                      set found_config $dir/opencode.json
                      break
                  end

                  set dir (path dirname $dir)
              end

              # An empty git_root makes the pattern `*`, so this is also the "no worktree" case.
              if test -z "$found_config"
                  and not string match -q -- "$git_root*" $HOME
                  and test -f $HOME/opencode.json
                  set found_config $HOME/opencode.json
              end

              if test -n "$found_config"
                  OPENCODE_CONFIG=$found_config ${lib.getExe config.programs.opencode.package} $argv
              else
                  ${lib.getExe config.programs.opencode.package} $argv
              end
            '';
        };

        opencode = {
          package =
            if config.programs.llmtrim.enable
            then llmtrimWrap "opencode" pkgs.llm-agents.opencode
            else pkgs.llm-agents.opencode;

          enableMcpIntegration = true;
          extraPlugins = [
            "context-mode"
          ];

          # `ai.agents` is deliberately NOT wired here. Those files are written in
          # Claude Code's frontmatter dialect and opencode rejects them outright:
          # `tools` is a comma-separated string where opencode wants an object,
          # `model` is an alias (sonnet/opus/inherit/default) where opencode wants
          # a provider/model ref, and softaworks' mermaid agent carries keys
          # (category/usage/input/output) opencode doesn't know. Feeding them in
          # fails config validation and opencode won't start. Translating the
          # frontmatter is possible but needs a real build-time YAML rewrite.
          commands =
            ai.commands
            // {
              autoresearch = builtins.readFile "${aro}/commands/autoresearch.md";
            };

          context = ./AGENTS.md;

          settings = {
            autoupdate = lib.mkDefault true;
            compaction = {
              auto = true;
              prune = true;
              reserved = 32000;
            };

            # opencode has no rules/ concept; load the shared language rule files
            # via the instructions glob (absolute store path, works even with
            # OPENCODE_DISABLE_CLAUDE_CODE=1).
            instructions = ["${ai.rulesDir}/*.md"];

            formatter = lib.mkDefault {
              alejandra = {
                command = [
                  "${lib.getExe pkgs.alejandra}"
                  "\$FILE"
                ];
                extensions = [".nix"];
              };
              gofmt = {disabled = true;};
              gofumpt = {
                command = [
                  "${lib.getExe pkgs.gofumpt}"
                  "-w"
                  "\$FILE"
                ];
                extensions = [".go"];
              };
              nixfmt = {disabled = true;};
              ruff-check = {
                command = [
                  "${lib.getExe pkgs.ruff}"
                  "check"
                  "\$FILE"
                ];
                extensions = [".py" ".pyi"];
              };
              rustfmt = {
                command = [
                  "rustfmt"
                  "+nightly"
                  "--edition=2024"
                  "\$FILE"
                ];
                extensions = [".rs"];
              };
              shfmt = {
                command = [
                  "${lib.getExe pkgs.shfmt}"
                  "-i"
                  "4"
                  "-ci"
                  "-sr"
                  "-s"
                  "-bn"
                  "-w"
                  "\$FILE"
                ];
                extensions = [".sh" ".bash"];
              };
              stylua = {
                command = [
                  "${lib.getExe pkgs.stylua}"
                  "\$FILE"
                ];
                extensions = [".lua"];
              };
            };

            lsp = lib.mkDefault (lib.removeAttrs opencodeLsp ["rust"]);

            permission = lib.mkDefault ai.permissions.opencode.permission;

            plugin =
              lib.optional pkgs.stdenv.hostPlatform.isDarwin my.pkgs.opencode-notifier.passthru.plugin
              ++ lib.optional config.programs.rtk.enable "${pkgs.llm-agents.rtk}/libexec/rtk/hooks/opencode/rtk.ts"
              ++ [
                "${aro}/plugins/autoresearch-context.ts"
                "${inputs.superpowers}/.opencode/plugins/superpowers.js"
              ]
              ++ config.programs.opencode.extraPlugins;

            watcher.ignore = [
              ".direnv/**"
              ".git/**"
              ".rumdl_cache/**"
              "dist/**"
              "node_modules/**"
              "target/**"
            ];
          };

          skills = autoresearchSkills;

          tui = {
            theme = "nord";
            scroll_acceleration = {
              enabled = true;
            };
          };
        };
      };
    })
  ];
}
