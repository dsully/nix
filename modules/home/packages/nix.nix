{
  my,
  pkgs,
  ...
}: {
  home = {
    packages = with pkgs;
      [
        alejandra
        cachix
        deadnix
        flake-checker
        nix-tree
        statix
      ]
      ++ (with lixPackageSets.latest; [
        nix-direnv
        nix-init
      ])
      ++ [
        my.pkgs.nh
        my.pkgs.nurl
      ];
  };
}
