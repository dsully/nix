# Evaluation-level plumbing that capability modules cannot express:
# external module imports, disabledModules, and the `my` module argument.
{
  inputs,
  lib,
  perSystem,
  pkgs,
  userModuleTarget,
  ...
}: let
  isHome = userModuleTarget == "home";
in {
  imports = lib.optionals isHome [
    inputs.agent-skills.homeManagerModules.default
    inputs.nix-index-database.homeModules.nix-index
    inputs.opnix.homeManagerModules.default
  ];

  # Don't bother building fonts that I don't use.
  disabledModules = lib.optionals isHome [
    "targets/darwin/copyapps.nix"
    "targets/darwin/default.nix"
    "targets/darwin/fonts.nix"
    "targets/darwin/keybindings.nix"
    "targets/darwin/search.nix"
  ];

  # This flake's packages layered over nixpkgs. A consuming flake passes ours
  # as perSystem.upstream.
  _module.args.my.pkgs =
    pkgs
    // (perSystem.upstream or perSystem.self)
    // lib.optionalAttrs (inputs ? neovim-nightly-overlay) {
      # CI builds and caches checks (dev-partition nixpkgs pin), not packages.
      inherit (inputs.neovim-nightly-overlay.checks.${pkgs.stdenv.hostPlatform.system}) neovim;
    };
}
