{
  config,
  inputs,
  lib,
  my,
  perSystem,
  pkgs,
  ...
}: let
  ai = import ./common.nix {inherit config inputs lib my perSystem pkgs;};
in {
  imports = [
    inputs.agent-skills.homeManagerModules.default
    ./ccstatusline.nix
    ./claude-code.nix
    ./codeburn.nix
    ./codex.nix
    ./icm.nix
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
    };

    home = {
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
          indxr
          just-mcp
          mcp-mux
          mcp-server-git-rs
          mcptools
          open-ralph-wiggum
          rust-mcp-server
        ]);

      sessionVariables = {
        "RTK_TELEMETRY_DISABLED" = "1";
      };
    };

    programs = {
      mcp = {
        enable = true;
        servers = ai.mcpServers;
      };

      agent-skills = {
        enable = true;
        sources = {
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
          # enableAll = [""];
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
