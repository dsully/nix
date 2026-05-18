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
        nix-tree
        nurl
        statix
      ]
      ++ [
        perSystem.nix-auth.nix-auth
        perSystem.self.nh
      ];
  };
}
