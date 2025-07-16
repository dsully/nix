{
  flake,
  perSystem,
  pkgs,
  ...
}: {
  imports = [
    flake.homeModules.dsully
    ../options.nix
  ];

  home = {
    packages = with pkgs;
      [
        bacon
        claude-code
        ghostscript_headless
        nix-output-monitor
        pandoc
      ]
      ++ (with perSystem.self; [
        autorebase
        git-ai-commit
        turbo-commit
      ]);
  };
}
