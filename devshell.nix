{pkgs}:
pkgs.mkShell {
  packages = with pkgs; [
    alejandra
    cachix
    deadnix
    fd
    fish
    jq
    just
    nh
    nurl
    ripgrep
    sd
    statix
  ];

  env = {};

  shellHook = "";
}
