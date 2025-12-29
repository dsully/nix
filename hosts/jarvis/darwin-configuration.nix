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
    flake.inputs.determinate.darwinModules.default
    flake.modules.darwin.common
    flake.modules.darwin.homebrew
    ./homebrew.nix
    ./options.nix
  ];
}
