{pkgs, ...}: {
  config.nixpkgs.hostPlatform = "x86_64-linux";

  environment.systemPackages = [pkgs.liquidctl];
}
