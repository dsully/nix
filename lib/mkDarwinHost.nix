# mkDarwinHost — a nix-darwin system plus the user's standalone home-manager
# config, from one host declaration. Fields: see mkHost in ./hostLib.nix.
#
# Signature: hostLib args -> host fields -> { system, homeConfigurations }
#
#   # modules/hosts/jarvis.nix
#   { mkDarwinHost }:
#   mkDarwinHost {
#     hostName = "jarvis";
#     userConfig.unifi.enable = true;
#   }
args @ {inputs, ...}:
(import ./hostLib.nix args).mkHost {
  platformDir = "darwin";
  buildSystem = {
    specialArgs,
    modules,
  }:
    inputs.nix-darwin.lib.darwinSystem {
      inherit (args) pkgs;
      inherit specialArgs modules;
    };
  systemModule.system.stateVersion = 6;
}
