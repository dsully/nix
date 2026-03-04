{
  perSystem,
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
        nh
        nix-tree
        nurl
        statix
      ]
      ++ [
        perSystem.nix-auth.nix-auth
      ];
  };
}
