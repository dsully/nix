{
  flake,
  pkgs,
  ...
}: {
  imports = [
    flake.homeModules.dsully
    flake.homeModules.copypaste
    ../options.nix
  ];

  home = {
    packages = with pkgs; [
      nix-output-monitor
    ];
  };

  services = {
    syncthing = {
      enable = true;
    };
  };
}
