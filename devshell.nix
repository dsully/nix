{
  perSystem,
  pkgs,
}:
perSystem.devshell.mkShell {
  packages = with pkgs;
    [
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
    ]
    ++ [
      perSystem.self.nix-package-updater
    ];
}
