{
  flake,
  perSystem,
  pkgs,
  ...
}: {
  _module.args.username = "dsully";

  imports = [
    flake.homeModules.dsully
    flake.homeModules.paste
    flake.homeModules.xdg-open-svc
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
        git-ai-commit
        reading-list-to-pinboard-rs
        turbo-commit
        werk
      ]);
  };
}
