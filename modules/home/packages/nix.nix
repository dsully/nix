{
  flake,
  pkgs,
  ...
}: {
  home = {
    packages = with (pkgs // ((flake.inputs.upstream or flake).packages.${pkgs.system} or {})); [
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
