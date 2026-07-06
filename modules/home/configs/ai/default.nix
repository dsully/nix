{
  config,
  inputs,
  lib,
  my,
  perSystem,
  pkgs,
  ...
}: let
  ai = import ./registry.nix {inherit config inputs lib my perSystem pkgs;};

  # headroom isn't in nixpkgs; it's installed via `uv tool` (headroom-ai[all])
  # into xdg.binHome. The programs.headroom module bakes ${package}/bin/headroom
  # into store-path launch wrappers, so hand it a store wrapper that execs the
  # uv-managed binary by absolute path.
  headroomBin = pkgs.writeShellScriptBin "headroom" ''
    exec ${config.xdg.binHome}/headroom "$@"
  '';

  # On PATH so per-repo project configs (.mcp.json / opencode.jsonc) can launch
  # the nixos MCP server by name. Tests are disabled to match flake.nix mkHome,
  # since the unmodified pkgs (e.g. the jarvis darwin eval path) would run them.
  mcp-nixos = pkgs.mcp-nixos.overridePythonAttrs (_: {doCheck = false;});
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
        ])
        ++ [mcp-nixos];
    };

    programs = {
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

      uv.tool.packages = [
        "headroom-ai[all]"
      ];
    };
  };
}
