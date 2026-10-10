{
  mkUserModule,
  config,
  inputs,
  lib,
  my,
  pkgs,
  ...
}: let
  ai = import ./shared/registry.nix {inherit config inputs lib my pkgs;};
in
  mkUserModule {
    name = "ai";

    home = {
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
          ])
          ++ [pkgs.mcp-nixos];
      };

      programs = {
        mcp = {
          enable = true;
          servers = ai.mcpServers;
        };
      };
    };
  }
