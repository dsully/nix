# mkSystemManagerHost — creates a system-manager config and the standalone
# home-manager configs of its users from one structured declaration. Same
# interface as mkDarwinHost.
#
# Signature: hostLib args -> { hostName, primaryUser, ... } -> { system, homeConfigurations }
#
# Fields:
#
#   hostName:          (required) Sets system.hostName.
#   primaryUser:       (required) User file function or plain username. Sets
#                      system.userName. system-manager does not manage the
#                      account itself.
#   users:             (optional) User file functions (mkUser files) that get
#                      a home-manager config on this host.
#   userConfig:        (optional) { <user> = { ... }; } host-specific additions
#                      to modules.users.<user>.
#   extraModules:      (optional) Additional system-manager modules.
#   extraHomeModules:  (optional) Additional home-manager modules.
#
# Usage:
#
#   # modules/hosts/zap.nix
#   { mkSystemManagerHost, users }:
#   mkSystemManagerHost {
#     hostName = "zap";
#     primaryUser = users.dsully;
#     users = [ users.dsully ];
#     extraModules = [ { modules.system.caddy.enable = true; } ];
#   }
args @ {inputs, ...}: let
  h = import ./hostLib.nix args;
in
  {
    hostName,
    primaryUser,
    users ? [],
    userConfig ? {},
    extraModules ? [],
    extraHomeModules ? [],
  }: {
    system = inputs.system-manager.lib.makeSystemConfig {
      specialArgs = h.specialArgsFor "system" {
        inherit (h) pkgs;
        system-manager = inputs.system-manager.packages.${h.pkgs.stdenv.hostPlatform.system}.default;
      };
      modules =
        [
          {
            system = {
              inherit hostName;
              userName = h.userName primaryUser;
            };
            modules.users = userConfig;
          }
        ]
        ++ map h.userModule users
        ++ extraModules
        ++ h.modulesExcept ["hosts" "users" "darwin"];
    };

    homeConfigurations = h.mkHomes {
      inherit hostName users userConfig;
      extraModules = extraHomeModules;
    };
  }
