{
  config,
  pkgs,
  ...
}: {
  devshells.default = {
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
        config.packages.nix-package-updater
      ];
  };
}
