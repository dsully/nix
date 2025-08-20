{
  my,
  perSystem,
  pkgs,
  ...
}: let
  nix-package-updater = (perSystem.upstream or perSystem).nix-package-updater.default;
in {
  imports = [
    ./development.nix
    ./editor.nix
    ./nix.nix
    ./rust.nix
    ./system.nix
  ];

  home = {
    # Handle merging nixpkgs, the packages in this flake and allowing dependent to use the packages from this flake.
    packages = with (pkgs // my.pkgs);
      [
        devmoji-log
        dirstat-rs
        feluda
        geil
        git-trim
        lolcate-rs
        magic-opener
        nix-package-updater
      ]
      ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
        fishPlugins.macos
        iproute2mac
        safari-rs
      ]
      ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
        xcp
      ];
  };
}
