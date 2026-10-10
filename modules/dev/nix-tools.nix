{
  mkUserModule,
  perSystem,
  pkgs,
  ...
}:
mkUserModule {
  name = "nix-tools";

  home = {
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
        ];
    };
  };
}
