{
  flake,
  perSystem,
  pkgs,
  ...
}: {
  imports = [
    flake.homeModules.dsully
    flake.homeModules.ai
    ../options.nix
  ];

  home = {
    packages = with pkgs;
      [
        bacon
        ghostscript_headless
        nix-output-monitor
        pandoc
      ]
      ++ (with perSystem.self; [
        autorebase
      ]);
  };
}
