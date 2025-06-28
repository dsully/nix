{
  flake,
  lib,
  ...
}: {
  # Disable home-manager via nix-darwin
  #
  # https://github.com/numtide/blueprint/issues/116
  home-manager.users = lib.mkForce {};

  imports = [
    flake.modules.common.nix
    flake.modules.darwin.common
    flake.modules.darwin.homebrew

    ./homebrew.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  networking = {
    computerName = "jarvis";
    hostName = "jarvis";
  };

  system.primaryUser = flake.lib.defaultUser;
}
