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
      ripgrep
      sd
      statix
    ]
    ++ [
      perSystem.self.nh
      perSystem.self.nix-package-updater
      perSystem.self.nurl
    ];
}
