{
  config,
  lib,
  pkgs,
  ...
}: let
  gitHubToken = "${config.xdg.cacheHome}/tokens/github-home.txt";
  group =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "staff"
    else "dsully";
in {
  programs = {
    nix-init = {
      enable = true;
      package = pkgs.lixPackageSets.latest.nix-init;

      settings = {
        maintainers = [config.system.userName];
        commit = false;
        access-tokens = lib.mkDefault {
          "github.com".file = gitHubToken;
        };
      };
    };

    onepassword-secrets = {
      enable = true;
      secrets = {
        gitHubToken = {
          reference = "op://Services/GitHub Home/token";
          path = gitHubToken;
          mode = "0600";
          inherit group;
        };
      };
    };
  };
}
