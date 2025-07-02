{
  flake,
  pkgs,
  system-manager,
  ...
}: {
  imports = [
    flake.modules.common.options
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
