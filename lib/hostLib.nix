# Shared plumbing for mkDarwinHost, mkSystemManagerHost, and the standalone
# home-manager configs they produce.
#
# Signature: { inputs, flake, perSystem, pkgs, extraModuleDirs? } -> helpers
#
#   inputs:          Flake inputs visible to modules (a consuming flake passes
#                    upstream inputs merged with its own).
#   flake:           Value of the `flake` specialArg.
#   perSystem:       Value of the `perSystem` specialArg for pkgs' system.
#   pkgs:            The package set shared by system and home evaluations.
#   extraModuleDirs: Additional module trees, discovered like ../modules.
{
  inputs,
  flake,
  perSystem,
  pkgs,
  extraModuleDirs ? [],
}: let
  inherit (inputs.nixpkgs) lib;

  discoverModules = import ./discoverModules.nix {inherit lib;};
  mkUser = import ./mkUser.nix;

  callUser = user: user {inherit lib mkUser;};
in rec {
  inherit pkgs;

  specialArgsFor = userModuleTarget: extra:
    {
      inherit flake inputs mkUser perSystem userModuleTarget;
      forPlatform = import ./forPlatform.nix pkgs.stdenv.hostPlatform.system;
      mkSystemModule = import ./mkSystemModule.nix;
      mkUserModule = import ./mkUserModule.nix;
      wrapperLib = inputs.nix-wrapper-modules.lib;
    }
    // extra;

  modulesExcept = exclude:
    lib.concatMap (modulesDir: discoverModules {inherit modulesDir exclude;})
    ([../modules] ++ extraModuleDirs);

  # Accepts a user file function (imported mkUser file) or a plain username.
  userName = user:
    if builtins.isString user
    then user
    else (callUser user).name;

  userModule = user: (callUser user).module;

  # One standalone home-manager configuration per user, keyed "<user>@<host>".
  mkHomes = {
    hostName,
    users,
    userConfig,
    extraModules,
  }:
    lib.listToAttrs (map (user: let
      name = userName user;
    in
      lib.nameValuePair "${name}@${hostName}" (
        inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = specialArgsFor "home" {homeUser = name;};
          modules =
            [
              (userModule user)
              {
                system.hostName = hostName;
                modules.users.${name} = userConfig.${name} or {};
              }
            ]
            ++ extraModules
            ++ modulesExcept ["hosts" "users" "darwin" "linux"];
        }
      ))
    users);
}
