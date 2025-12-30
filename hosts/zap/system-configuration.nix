{
  flake,
  pkgs,
  system-manager,
  ...
}: {
  imports = [
    flake.modules.system-manager.common
    ./options.nix
  ];

  config = {
    environment = {
      systemPackages = with pkgs; [
        fish
        system-manager
      ];
    };

    nixpkgs.hostPlatform = "x86_64-linux";
  };
}
