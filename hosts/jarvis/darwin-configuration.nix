{
  config,
  flake,
  lib,
  ...
}: {
  # Disable home-manager via nix-darwin
  #
  # https://github.com/numtide/blueprint/issues/116
  home-manager.users = lib.mkForce {};

  imports = [
    flake.inputs.determinate.darwinModules.default
    flake.modules.darwin.common
    flake.modules.darwin.homebrew
    ./homebrew.nix
    ./options.nix
  ];

  determinate-nix.customSettings = config.system.nixSettings;
}
