{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      cachix
      deadnix
      flake-checker
      nh
      nix-converter
      nix-init
      nix-tree
      nix-update
      nixpkgs-lint-community
      njq
      nurl
      nvd
      statix
    ];
  };
}
