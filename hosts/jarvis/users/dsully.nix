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
  ];

  system.hostName = "jarvis";

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
        git-ai-commit
        reading-list-to-pinboard-rs
        turbo-commit
      ]);
  };
}
