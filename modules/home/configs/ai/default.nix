{
  config,
  inputs,
  lib,
  my,
  perSystem,
  pkgs,
  ...
}: let
  aiLib = import ./lib.nix {inherit config inputs lib my pkgs;};
  aiAgents = import ./agents.nix {inherit aiLib inputs lib;};
in {
  imports = [
    inputs.skills-nix.homeModules.default
    ./agentgateway.nix
    ./ccstatusline.nix
    ./claude-code.nix
    ./codex.nix
    ./opencode.nix
  ];

  config = {
    _module.args = {
      inherit aiAgents aiLib;
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
          prerelease = true;
          withPackages = ["cocoindex>=1.0.0a24"];
        }
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
            # gemini-cli
            # goose-cli
            rtk
          ]
        )
        ++ (with my.pkgs; [
          agentgateway
          git-remote-mcp
          icm
          mcp-git-tools
          mcp-rust-analyzer
          mcp-rust-builder
          open-ralph-wiggum
          rust-mcp-filesystem
          rust-mcp-server
          treesitter-mcp
        ]);
    };

    programs = {
      mcp = {
        enable = true;
        servers = aiLib.mcpServers;
      };

      skills = {
        enable = true;
        defaultAgents = ["codex" "claude-code" "opencode"];
        sources = [
          {
            source = "obra/superpowers";
            skills = {
              exclude = ["commit-work"];
            };
          }
          {
            source = "cocoindex-io/cocoindex-code";
            skills = ["*"];
          }
          {
            source = "idjoo/skills";
            skills = ["commit"];
          }
          {
            source = "wshobson/agents";
            skills = [
              "architecture-patterns"
              "debugging-strategies"
              "e2e-testing-patterns"
              "error-handling-patterns"
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
              "rust-async-patterns"
              "uv-package-manager"
            ];
          }
        ];
      };
    };
  };
}
