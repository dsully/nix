{
  flake,
  perSystem,
  pkgs,
  ...
}: {
  _module.args.username = "dsully";

  imports = [
    flake.homeModules.dsully
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
