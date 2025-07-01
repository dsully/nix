{
  config,
  flake,
  lib,
  ...
}: rec {
  # Disable home-manager via nix-darwin
  #
  # https://github.com/numtide/blueprint/issues/116
  home-manager.users = lib.mkForce {};

  system.hostName = "jarvis";

  imports = [
    flake.modules.common.nix
    flake.modules.darwin.common
    flake.modules.darwin.homebrew

    ./homebrew.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  networking = {
    computerName = system.hostName;
    inherit (system) hostName;
  };

  system.primaryUser = config.system.userName;
}
