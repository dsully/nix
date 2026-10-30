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
  #   extraHomeUsers:    Other users with their own standalone home-manager
  #                      config "<name>@<hostName>" (e.g. root), as
  #                      name -> { userConfig?, extraHomeModules?, homeStateVersion?, group? }.
  #                      Modules default to off for them (defaultEnable = false),
  #                      so userConfig lists the ones to turn on. Home only: the
  #                      system evaluation sees the primary user alone.
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
    extraHomeUsers ? {},
  }: let
    specialArgsFor = userModuleTarget: extra:
      {
        inherit inputs perSystem userModuleTarget;
        flake = {inherit inputs;};
        forPlatform = import ./forPlatform.nix system;
        hideFromModel = import ./hideFromModel.nix {inherit lib;};
        mkSystemModule = import ./mkSystemModule.nix;
        mkUserModule = import ./mkUserModule.nix;
        wrapperLib = inputs.nix-wrapper-modules.lib;
      }
      // extra;

    modulesExcept = exclude:
      lib.concatMap (modulesDir: discoverModules {inherit modulesDir exclude;})
      ([../modules] ++ extraModuleDirs);

    # Read by mkUserModule as the default of every module's enable option.
    userDefaults = {
      options.modules.users = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options.defaultEnable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Default of this user's module enables; false makes every module opt-in.";
          };
        });
      };
    };

    identity = {
      system = {
        inherit hostName;
        userName = user;
      };
      modules.users = lib.optionalAttrs home {${user} = userConfig;};
    };

    homeDirectoryOf = name:
      if pkgs.stdenv.hostPlatform.isDarwin
      then
        if name == "root"
        then "/var/root"
        else "/Users/${name}"
      else if name == "root"
      then "/root"
      else "/home/${name}";

    # The flake's working tree, which other users' configs point back at.
    flakeDir = "${homeDirectoryOf user}/.config/nix";

    mkHomeConfiguration = name: {
      stateVersion,
      modules,
    }:
      inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = specialArgsFor "home" {homeUser = name;};
        modules =
          [
            userDefaults
            {
              home = {
                username = name;
                homeDirectory = homeDirectoryOf name;
                inherit stateVersion;
              };
            }
          ]
          ++ modules
          ++ modulesExcept ["hosts" "darwin" "linux"];
      };
  in {
    system = buildSystem {
      specialArgs = specialArgsFor "system" {};
      modules =
        [userDefaults identity systemModule]
        ++ extraModules
        ++ modulesExcept (lib.remove platformDir ["hosts" "darwin" "linux"]);
    };

    homeConfigurations =
      lib.optionalAttrs home {
        "${user}@${hostName}" = mkHomeConfiguration user {
          stateVersion = homeStateVersion;
          modules = [identity] ++ extraHomeModules;
        };
      }
      // lib.mapAttrs' (name: extra:
        lib.nameValuePair "${name}@${hostName}" (mkHomeConfiguration name {
          stateVersion = extra.homeStateVersion or homeStateVersion;
          modules =
            [
              {
                system = {
                  inherit hostName;
                  # The person, not the account: git identity, GitHub handle.
                  userName = user;
                  primaryGroup = extra.group or name;
                };
                modules.users.${name} = {defaultEnable = false;} // extra.userConfig or {};
                dotfiles.dir = "${flakeDir}/dotfiles";
                programs.nh.flake = flakeDir;
              }
            ]
            ++ extra.extraHomeModules or [];
        }))
      extraHomeUsers;
  };
}
