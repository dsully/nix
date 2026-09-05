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
    ./llmtrim.nix
    ./opencode.nix
    ./pi.nix
    ./rtk.nix
    ./skills
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
          with pkgs.llm-agents;
            [
              opencode2
              ralph-tui
            ]
            ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
              agent-browser
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

      # Mutually exclusive with programs.headroom (asserted in llmtrim.nix).
      # mkDefault so a downstream flake can enable it with a plain assignment.
      llmtrim.enable = lib.mkDefault false;

      mcp = {
        enable = true;
        servers = ai.mcpServers;
      };

      pi-coding-agent.enable = false;
    };
  };
}
