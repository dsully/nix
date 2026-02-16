{
  my,
  pkgs,
  ...
}: {
  imports = [
    ./development.nix
    ./editor.nix
    ./javascript.nix
    ./nix.nix
    ./python.nix
    ./rust.nix
    ./system.nix
  ];

  home = {
    # Handle merging nixpkgs, the packages in this flake and allowing dependent to use the packages from this flake.
    packages = with my.pkgs;
      [
        devmoji-log
        dirstat-rs
        geil
        lolcate-rs
        magic-opener
        nix-package-updater
      ]
      ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        fishPlugins.macos
        iproute2mac
        safari-rs
      ]
      ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        syncthing
      ];
  };
}
