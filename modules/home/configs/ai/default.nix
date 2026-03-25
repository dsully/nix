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

  home = {
    packages =
      (
        with perSystem.llm-agents; [
          claude-code-acp
          # codex
          # gemini-cli
          # goose-cli
        ]
      )
      ++ (with my.pkgs; [
        cargo-mcp
        crates-mcp
        git-mcp-rs
        # infiniloom
        mcp-git-tools
        mcp-rust-analyzer
        mcp-rust-builder
        # memory-mcp-1file
        rust-mcp-filesystem
        rust-mcp-server
        sentry-mcp
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
}
