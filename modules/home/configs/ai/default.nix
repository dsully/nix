{
  config,
  inputs,
  lib,
  my,
  perSystem,
  pkgs,
  ...
}: let
  ai = import ./common.nix {inherit config inputs lib my pkgs;};
in {
  imports = [
    inputs.agent-skills.homeManagerModules.default
    ./ccstatusline.nix
    ./claude-code.nix
    ./codeburn.nix
    ./codex.nix
    ./opencode.nix
  ];

  config = {
    _module.args = {
      inherit ai;
    };

    packageTools = {
      javascript = [
        "opencode-claude-auth"
        "opencode-gemini-auth@latest"
        "opencode-with-claude"
      ];
      python = [
        # https://github.com/cocoindex-io/cocoindex-code
        {
          package = "cocoindex-code";
          extras = "full";
          prerelease = true;
          withPackages = ["cocoindex>=1.0.0a24"];
        }
      ];
    };

    home = {
      # Link the notifier app bundles into ~/Applications and register them
      # with LaunchServices, so notifications are delivered and the apps appear
      # in System Settings → Notifications. The plugin/hook launch them from
      # this stable path. (agent-notifier is emptyFile off darwin.)
      file = lib.mkIf pkgs.stdenv.isDarwin {
        "Applications/ClaudeCodeNotifier.app".source = "${my.pkgs.agent-notifier}/Applications/ClaudeCodeNotifier.app";
        "Applications/OpenCodeNotifier.app".source = "${my.pkgs.agent-notifier}/Applications/OpenCodeNotifier.app";
      };

      activation.registerNotifierApps = lib.mkIf pkgs.stdenv.isDarwin (
        lib.hm.dag.entryAfter ["linkGeneration"] ''

          lsregister=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

          for app in ClaudeCodeNotifier OpenCodeNotifier; do
            $DRY_RUN_CMD "$lsregister" -f "$HOME/Applications/$app.app"
          done
        ''
      );

      # cocoindex-code is installed via uv in the python activation script;
      # `ccc init` performs its one-time setup and is idempotent on re-runs.
      activation.cocoindexInit = lib.mkIf (lib.any (t: t.package == "cocoindex-code") config.packageTools.python) (
        lib.hm.dag.entryAfter ["python"] ''
          $DRY_RUN_CMD ${config.xdg.binHome}/ccc init || true
        ''
      );

      packages =
        (
          with perSystem.llm-agents; [
            # Used by codecompanion
            claude-agent-acp
            codex
            codex-acp
            ralph-tui
            rtk
          ]
        )
        ++ (with my.pkgs; [
          git-remote-mcp
          icm
          just-mcp
          mcp-mux
          mcp-rust-analyzer
          mcp-rust-builder
          mcp-server-git-rs
          open-ralph-wiggum
          rust-mcp-server
        ]);
    };

    programs = {
      mcp = {
        enable = true;
        servers = ai.mcpServers;
      };

      agent-skills = {
        enable = true;
        sources = {
          cocoindex-code = {
            input = "cocoindex-code";
            subdir = "skills";
          };
          idjoo-skills = {
            input = "idjoo-skills";
          };
          local = {
            path = ./skills;
          };
          superpowers = {
            input = "superpowers";
            subdir = "skills";
          };
          wshobson-backend-development = {
            input = "wshobson-agents";
            subdir = "plugins/backend-development/skills";
          };
          wshobson-developer-essentials = {
            input = "wshobson-agents";
            subdir = "plugins/developer-essentials/skills";
          };
          wshobson-python-development = {
            input = "wshobson-agents";
            subdir = "plugins/python-development/skills";
          };
          wshobson-systems-programming = {
            input = "wshobson-agents";
            subdir = "plugins/systems-programming/skills";
          };
        };
        skills = {
          enable = [
            "architecture-patterns"
            "brainstorming"
            "ccc"
            "commit"
            "debugging-strategies"
            "dispatching-parallel-agents"
            "e2e-testing-patterns"
            "error-handling-patterns"
            "executing-plans"
            "finishing-a-development-branch"
            "memory-safety-patterns"
            "python-anti-patterns"
            "python-code-style"
            "python-configuration"
            "python-design-patterns"
            "python-error-handling"
            "python-observability"
            "python-performance-optimization"
            "python-project-structure"
            "python-resilience"
            "python-resource-management"
            "python-testing-patterns"
            "python-type-safety"
            "receiving-code-review"
            "requesting-code-review"
            "rust-async-patterns"
            "subagent-driven-development"
            "systematic-debugging"
            "test-driven-development"
            "using-git-worktrees"
            "using-superpowers"
            "uv-package-manager"
            "verification-before-completion"
            "visual-explainer"
            "writing-plans"
            "writing-skills"
          ];
          enableAll = ["cocoindex-code"];
        };
        targets = {
          claude.enable = true;
          codex.enable = true;
          opencode.enable = true;
        };
      };
    };
  };
}
