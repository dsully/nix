{
  flake,
  perSystem,
  pkgs,
  ...
}: {
  imports = [
    flake.homeModules.dsully
    flake.homeModules.ghostty
    flake.homeModules.paste
    flake.homeModules.xdg-open-svc
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
        apple-photos-export
        autorebase
        reading-list-to-pinboard-rs
      ]);
  };
}
