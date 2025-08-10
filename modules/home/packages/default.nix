{
  flake,
  pkgs,
  ...
}: let
  local = (flake.inputs.upstream or flake).packages.${pkgs.system} or {};

  nix-package-updater = (flake.inputs.upstream or flake).inputs.nix-package-updater.outputs.defaultPackage.${pkgs.system};
in {
  imports = [
    ./ai.nix
    ./development.nix
    ./editor.nix
    ./nix.nix
    ./rust.nix
    ./system.nix
  ];

  home = {
    # Handle merging nixpkgs, the packages in this flake and allowing dependent to use the packages from this flake.
    packages = with (pkgs // local);
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
