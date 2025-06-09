{
  perSystem,
  pkgs,
  ...
}: {
  home = {
    packages = with pkgs;
      [
        cachix
        deadnix
        flake-checker
        nh
        nix-converter
        nix-init
        nix-tree
        nix-update
        nixpkgs-lint-community
        nurl
        nvd
        statix
      ]
      ++ (with perSystem.self; [
        njq
      ]);
  };
}
