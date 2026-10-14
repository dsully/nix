{
  config,
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
      overrideDevices = false;
      overrideFolders = false;

      settings = {
        devices = {
          jarvis.id = "CJJNY5K-SNQH3XE-ECXUC6U-KI23MC7-GV5SPSZ-5AYUOCC-7YCUBLD-T2TU5AU";
          server.id = "XJ2IXBX-2MECPAU-VNQW4KW-XDHL7VP-HJ6WWHQ-IVUH6JN-L2DJYXC-KU2XAAO";
          zap.id = "YM2JONQ-CEWHM7Z-3DXAB4E-SZ4KCOX-QC6HAQI-3XCHVPE-PR5IWJA-SXXCNQC";
        };

        folders.dev-home = {
          label = "dev personal";
          path = "${config.home.homeDirectory}/dev/home";
          devices = ["jarvis" "server" "zap"];
          ignorePatterns = ["#include .stglobalignore"];
        };
      };
    };
  };
}
