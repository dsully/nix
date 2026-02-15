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
      ++ [
        my.pkgs.nh
        my.pkgs.nurl
      ];
  };
}
