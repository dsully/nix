{
  inputs,
  my,
  pkgs,
  ...
}: let
  anthropic-api-key = inputs.anthropic-api-key.packages.${pkgs.system}.default;
  nix-package-updater = inputs.nix-package-updater.packages.${pkgs.system}.default;
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
        anthropic-api-key
        devmoji-log
        dirstat-rs
        geil
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
        syncthing
        xcp
      ];
  };
}
