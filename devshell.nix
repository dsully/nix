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
        nurl
        ripgrep
        sd
        statix
      ]
      ++ [
        config.packages.nix-package-updater
        config.packages.nh
      ];
  };
}
