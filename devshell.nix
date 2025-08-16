{
  inputs,
  pkgs,
}:
pkgs.mkShell {
  packages = with pkgs; [
    inputs.nix-package-updater.defaultPackage.${pkgs.system}

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
