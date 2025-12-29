{
  flake,
  pkgs,
  system-manager,
  ...
}: {
  imports = [
    flake.modules.common.nix
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
