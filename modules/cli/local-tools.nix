{
  mkUserModule,
  my,
  pkgs,
  ...
}:
mkUserModule {
  name = "local-tools";

  home = {
    home = {
      packages = with my.pkgs;
        [
          devmoji-log
          magic-opener
          nix-package-updater
        ]
        ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
          fishPlugins.macos
          iproute2mac
          safari-rs
        ];
    };
  };
}
