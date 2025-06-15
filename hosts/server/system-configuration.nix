{
  pkgs,
  system-manager,
  ...
}: {
  config = {
    environment.systemPackages = with pkgs; [
      liquidctl
      system-manager
    ];

    nixpkgs.hostPlatform = "x86_64-linux";
  };
}
