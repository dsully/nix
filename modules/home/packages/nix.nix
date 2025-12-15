{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      alejandra
      cachix
      deadnix
      flake-checker
      nix-direnv
      nix-init
      nix-inspect
      nix-tree
      nurl
      statix
    ];
  };
}
