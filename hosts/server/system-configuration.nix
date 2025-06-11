{pkgs, ...}: {
  config = {
    environment.systemPackages = with pkgs; [
      liquidctl
    ];

    nixpkgs.hostPlatform = "x86_64-linux";
  };
}
