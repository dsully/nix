{
  perSystem,
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
        nurl
        statix
      ]
      ++ [
        perSystem.nix-auth.nix-auth
        my.pkgs.nh
      ];
  };
}
