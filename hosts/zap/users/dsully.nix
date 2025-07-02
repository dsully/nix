{
  flake,
  pkgs,
  ...
}: {
  imports = [
    flake.homeModules.dsully
    ../options.nix
  ];

  home = {
    packages = with pkgs; [
      nix-output-monitor
      pandoc
    ];
  };
}
