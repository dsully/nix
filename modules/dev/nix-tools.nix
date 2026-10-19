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
          deadnix
          flake-checker
          nix-output-monitor
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
