{
  inputs,
  perSystem,
  pkgs,
}: let
  nix-package-updater = inputs.nix-package-updater.defaultPackage.${pkgs.system};
in
  perSystem.devshell.mkShell {
    packages = with pkgs;
      [
        alejandra
        cachix
        deadnix
        fd
        fish
        jq
        just
        nh
        nurl
        ripgrep
        sd
        statix
      ]
      ++ [
        nix-package-updater
      ];
  }
