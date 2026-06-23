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

  # headroom isn't in nixpkgs; it's installed via `uv tool` (headroom-ai[all])
  # into xdg.binHome. The programs.headroom module bakes ${package}/bin/headroom
  # into store-path launch wrappers, so hand it a store wrapper that execs the
  # uv-managed binary by absolute path.
  headroomBin = pkgs.writeShellScriptBin "headroom" ''
    exec ${config.xdg.binHome}/headroom "$@"
  '';
in {
  imports = [
    inputs.agent-skills.homeManagerModules.default
    ./ccstatusline.nix
    ./claude-code.nix
    ./codeburn.nix
    ./codex.nix
    ./headroom.nix
    ./icm.nix
    ./opencode.nix
    ./pi.nix
    ./rtk.nix
  ];

  config = {
    _module.args = {
      inherit ai;
    };

    home = {
      packages =
        (
          with pkgs; [
            entire
          ]
        )
        ++ (
          with perSystem.llm-agents; [
            ralph-tui
          ]
        )
        ++ (with my.pkgs; [
          git-remote-mcp
          indxr
          just-mcp
          mcp-mux
          mcp-server-git-rs
          mcptools
          rust-mcp-server
        ]);
    };

    programs = {
      agent-skills = {
        enable = true;
        sources =
          {
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
            # wshobson-backend-development = {
            #   input = "wshobson-agents";
            #   subdir = "plugins/backend-development/skills";
            # };
            wshobson-developer-essentials = {
              input = "wshobson-agents";
              subdir = "plugins/developer-essentials/skills";
            };
            wshobson-python-development = {
              input = "wshobson-agents";
              subdir = "plugins/python-development/skills";
            };
            # wshobson-systems-programming = {
            #   input = "wshobson-agents";
            #   subdir = "plugins/systems-programming/skills";
            # };
          }
          // ai.marketplaceSkillSources;
        skills = {
          enable = [
            # "architecture-patterns"
            "brainstorming"
            "commit"
            "debugging-strategies"
            "dispatching-parallel-agents"
            "e2e-testing-patterns"
            "error-handling-patterns"
            "executing-plans"
            "finishing-a-development-branch"
            # "memory-safety-patterns"
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
            # "rust-async-patterns"
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
          enableAll = ai.marketplaceEnableAll;
        };
        targets = {
          claude.enable = true;
          codex.enable = true;
          opencode.enable = true;
          pi = {
            enable = true;
            dest = "${config.home.homeDirectory}/.pi/agent/skills";
            structure = "symlink-tree";
          };
        };
      };

      headroom = {
        enable = true;
        package = headroomBin;

        integrations.claudeCode.enable = true;

        optimization = {
          interceptToolResults = true;
          codeAware = true;
        };
      };

      icm = {
        enable = false;
      };

      mcp = {
        enable = true;
        servers = ai.mcpServers;
      };

      uv.tool.packages = [
        "headroom-ai[all]"
      ];
    };
  };
}
