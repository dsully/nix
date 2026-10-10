{
  lib,
  mkUserModule,
  pkgs,
  ...
}:
mkUserModule {
  name = "syncthing";

  home = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    home.packages = [pkgs.syncthing];

    services.syncthing = {
      enable = true;
      extraOptions = ["--log-level=WARN"];
    };
  };
}
