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

  services = {
    syncthing = {
      enable = true;
      guiAddress = "0.0.0.0:8384";
    };
  };
}
