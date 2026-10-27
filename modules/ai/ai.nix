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

    # Default tool set; a host turns one off with `<tool>.enable = false`.
    requires = [
      "ccstatusline"
      "claude-code"
      "mcp-mux"
      "skills"
    ];

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
              lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
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
          ]);
      };

      programs = {
        mcp = {
          enable = true;
          servers = ai.mcpServers;
        };
      };
    };
  }
