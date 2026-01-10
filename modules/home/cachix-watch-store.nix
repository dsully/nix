{
  config,
  lib,
  pkgs,
  ...
}: let
  cacheName = "dsully";
  tokenPath = ".config/cachix/auth-token";
in
  lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    programs.onepassword-secrets = {
      enable = true;
      secrets.cachixAuthToken = {
        reference = "op://Services/Cachix/token";
        path = tokenPath;
        mode = "0600";
      };
    };

    launchd.agents.cachix-watch-store = {
      enable = true;
      config = {
        ProgramArguments = [
          "${pkgs.writeShellScript "cachix-watch" ''
            export CACHIX_AUTH_TOKEN=$(cat ${config.home.homeDirectory}/${tokenPath})
            exec ${pkgs.cachix}/bin/cachix watch-store ${cacheName}
          ''}"
        ];
        KeepAlive = true;
        RunAtLoad = true;
        ProcessType = "Background";
        StandardOutPath = "${config.xdg.cacheHome}/cachix-watch-store.log";
        StandardErrorPath = "${config.xdg.cacheHome}/cachix-watch-store.log";
      };
    };
  }
