{
  config,
  inputs,
  lib,
  my,
  perSystem,
  pkgs,
  ...
}: let
  aiLib = import ./lib.nix {inherit config inputs lib my perSystem pkgs;};
in {
  imports = [
    inputs.charmbracelet-nur.homeModules.crush
    inputs.skills-nix.homeModules.default
    ./ccstatusline.nix
    ./claude-code.nix
    ./opencode.nix
  ];

  config = {
    packageTools = {
      javascript = [
        "opencode-claude-auth"
        "opencode-gemini-auth@latest"
      ];
      python = [
        # https://github.com/cocoindex-io/cocoindex-code
        {
          package = "cocoindex-code";
          prerelease = true;
          withPackages = ["cocoindex>=1.0.0a24"];
        }
        {package = "git+https://github.com/ast-grep/ast-grep-mcp";}
        {package = "mcp-nixos";}
      ];
    };

    home = {
      packages =
        (
          with perSystem.llm-agents; [
            # Used by codecompanion
            claude-code-acp
            codex
            codex-acp
            # gemini-cli
            # goose-cli
            rtk
          ]
        )
        ++ (with my.pkgs; [
          cargo-mcp
          crates-mcp
          git-mcp-rs
          mcp-git-tools
          mcp-rust-analyzer
          mcp-rust-builder
          open-ralph-wiggum
          rust-mcp-filesystem
          rust-mcp-server
          treesitter-mcp
          turbo-commit
        ]);
    };

    programs = {
      mcp = {
        enable = true;
        servers = aiLib.mcpServers;
      };

      skills = {
        enable = true;
        defaultAgents = ["opencode" "claude-code"];
        sources = [
          "cocoindex-io/cocoindex-code"
          "dabiggm0e/autoresearch-opencode"
          "wshobson/agents"
          "vercel-labs/agent-skills"
        ];
      };
    };
  };
}
