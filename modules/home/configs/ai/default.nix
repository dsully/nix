{
  config,
  inputs,
  lib,
  my,
  pkgs,
  ...
}: let
  ai = import ./registry.nix {inherit config inputs lib my pkgs;};
in {
  imports = [
    ./ccstatusline.nix
    ./claude-code.nix
    ./codex.nix
    ./headroom.nix
    ./icm.nix
    ./opencode.nix
    ./pi.nix
    ./rtk.nix
    ./skills
    ./zaly.nix
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
          with pkgs.llm-agents; [
            agent-browser
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
        ])
        ++ [pkgs.mcp-nixos];
    };

    programs = {
      codex.enable = false;

      headroom = {
        enable = false;

        integrations.claudeCode.enable = true;
      };

      icm = {
        enable = false;
      };

      mcp = {
        enable = true;
        servers = ai.mcpServers;
      };

      pi-coding-agent.enable = false;
    };
  };
}
