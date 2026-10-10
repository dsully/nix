# mkDarwinHost — creates a nix-darwin system and the standalone home-manager
# configs of its users from one structured declaration.
#
# Signature: hostLib args -> { hostName, primaryUser, ... } -> { system, homeConfigurations }
#
# The first argument is the attrset documented in ./hostLib.nix.
#
# Fields:
#
#   hostName:          (required) Sets system.hostName.
#   primaryUser:       (required) User file function or plain username. Sets
#                      system.userName (and through it system.primaryUser).
#   stateVersion:      (optional, default 6) nix-darwin state version.
#   users:             (optional) User file functions (mkUser files).
#   userConfig:        (optional) { <user> = { ... }; } host-specific additions
#                      to modules.users.<user>, applied to the system and home
#                      evaluations alike.
#   extraModules:      (optional) Additional nix-darwin modules.
#   extraHomeModules:  (optional) Additional home-manager modules.
#
# Usage:
#
#   # modules/hosts/jarvis.nix
#   { mkDarwinHost, users }:
#   mkDarwinHost {
#     hostName = "jarvis";
#     primaryUser = users.dsully;
#     users = [ users.dsully ];
#     userConfig.dsully.unifi.enable = true;
#   }
args @ {inputs, ...}: let
  h = import ./hostLib.nix args;
in
  {
    hostName,
    primaryUser,
    stateVersion ? 6,
    users ? [],
    userConfig ? {},
    extraModules ? [],
    extraHomeModules ? [],
  }: {
    system = inputs.nix-darwin.lib.darwinSystem {
      inherit (h) pkgs;
      specialArgs = h.specialArgsFor "system" {};
      modules =
        [
          {
            system = {
              inherit hostName stateVersion;
              userName = h.userName primaryUser;
            };
            modules.users = userConfig;
          }
        ]
        ++ map h.userModule users
        ++ extraModules
        ++ h.modulesExcept ["hosts" "users" "linux"];
    };

    homeConfigurations = h.mkHomes {
      inherit hostName users userConfig;
      extraModules = extraHomeModules;
    };
  }
