{
  flake,
  perSystem,
  pkgs,
  ...
}: {
  imports = [
    flake.homeModules.${flake.lib.defaultUser}
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
        git-ai-commit
        turbo-commit
      ]);
  };
}
