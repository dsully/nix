{
  config,
  inputs,
  lib,
  my,
  pkgs,
  ...
}: let
  ai = import ./registry.nix {inherit config inputs lib my pkgs;};

  # headroom isn't in nixpkgs; it's installed via `uv tool` (headroom-ai[all])
  # into xdg.binHome. The programs.headroom module bakes ${package}/bin/headroom
  # into store-path launch wrappers, so hand it a store wrapper that execs the
  # uv-managed binary by absolute path.
  headroomBin = pkgs.writeShellScriptBin "headroom" ''
    exec ${config.xdg.binHome}/headroom "$@"
  '';
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
        enable = true;
        package = headroomBin;

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

      uv.tool.packages = [
        "headroom-ai[all]"
      ];
    };
  };
}
