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
          nurl
          statix
        ]
        ++ [
          perSystem.nix-auth.nix-auth
        ];
    };
  };
}
