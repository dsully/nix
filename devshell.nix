{pkgs}:
pkgs.mkShell {
  packages = [
    pkgs.cachix
    pkgs.fish
    pkgs.just
    pkgs.ripgrep
  ];

  env = {};

  shellHook = "";
}
