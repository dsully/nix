{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      alejandra
      cachix
      deadnix
      flake-checker
      nh
      nix-converter
      nix-direnv
      nix-init
      nix-tree
      nix-update
      nixpkgs-lint-community
      nurl
      nvd
      statix
    ];
  };
}
