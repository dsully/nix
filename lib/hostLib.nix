# Shared body of mkDarwinHost and mkSystemManagerHost: one host declaration
# yields the system config and the user's standalone home-manager config.
#
# Signature: { inputs, pkgs, packages, extraModuleDirs?, upstreamPackages? } -> { mkHost }
#
#   inputs:           Flake inputs visible to modules (a consuming flake passes
#                     upstream inputs merged with its own).
#   pkgs:             The package set shared by system and home evaluations.
#   packages:         The calling flake's packages for pkgs' system
#                     (`perSystem.self`).
#   extraModuleDirs:  Additional module trees, discovered like ../modules.
#   upstreamPackages: Set by this flake's exported `lib` so a consuming flake's
#                     modules see this flake's packages as `perSystem.upstream`.
{
  inputs,
  pkgs,
  packages,
  extraModuleDirs ? [],
  upstreamPackages ? null,
}: let
  inherit (inputs.nixpkgs) lib;
  inherit (pkgs.stdenv.hostPlatform) system;

  discoverModules = import ./discoverModules.nix {inherit lib;};
  perSystem =
    {
      self = packages;
      devshell = inputs.devshell.legacyPackages.${system};
      llm-agents = inputs.llm-agents.packages.${system};
      nix-auth = inputs.nix-auth.packages.${system};
    }
    // lib.optionalAttrs (upstreamPackages != null) {
      upstream = upstreamPackages.${system};
    };
in {
  # Platform half, supplied by the factory:
  #   buildSystem: { specialArgs, modules } -> system config
  #   platformDir: the system-only module directory this platform includes
  #   systemModule: platform defaults (e.g. nix-darwin stateVersion)
  #
  # Host fields:
  #   hostName:          (required) Sets system.hostName.
  #   user:              (default "dsully") Primary user; owns the home config.
  #   homeStateVersion:  (default "25.05") home-manager state version.
  #   home:              (default true) false for hosts without a home config.
  #   userConfig:        Additions to modules.users.<user> (module enables and
  #                      options), applied to the system and home evaluations.
  #   extraModules:      Additional system modules.
  #   extraHomeModules:  Additional home-manager modules (host-only data).
  mkHost = {
    buildSystem,
    platformDir,
    systemModule ? {},
  }: {
    hostName,
    user ? "dsully",
    homeStateVersion ? "25.05",
    home ? true,
    userConfig ? {},
    extraModules ? [],
    extraHomeModules ? [],
  }: let
    specialArgsFor = userModuleTarget: extra:
      {
        inherit inputs perSystem userModuleTarget;
        flake = {inherit inputs;};
        forPlatform = import ./forPlatform.nix system;
        mkSystemModule = import ./mkSystemModule.nix;
        mkUserModule = import ./mkUserModule.nix;
        wrapperLib = inputs.nix-wrapper-modules.lib;
      }
      // extra;

    modulesExcept = exclude:
      lib.concatMap (modulesDir: discoverModules {inherit modulesDir exclude;})
      ([../modules] ++ extraModuleDirs);

    identity = {
      system = {
        inherit hostName;
        userName = user;
      };
      modules.users = lib.optionalAttrs home {${user} = userConfig;};
    };
  in {
    system = buildSystem {
      specialArgs = specialArgsFor "system" {};
      modules =
        [identity systemModule]
        ++ extraModules
        ++ modulesExcept (lib.remove platformDir ["hosts" "darwin" "linux"]);
    };

    homeConfigurations = lib.optionalAttrs home {
      "${user}@${hostName}" = inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = specialArgsFor "home" {homeUser = user;};
        modules =
          [
            identity
            {
              home = {
                username = user;
                homeDirectory =
                  if pkgs.stdenv.hostPlatform.isDarwin
                  then "/Users/${user}"
                  else "/home/${user}";
                stateVersion = homeStateVersion;
              };
            }
          ]
          ++ extraHomeModules
          ++ modulesExcept ["hosts" "darwin" "linux"];
      };
    };
  };
}
