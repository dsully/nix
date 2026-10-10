# mkSystemManagerHost — a system-manager config plus the user's standalone
# home-manager config, from one host declaration. Fields: see mkHost in
# ./hostLib.nix. system-manager does not manage the user account itself.
#
# Signature: hostLib args -> host fields -> { system, homeConfigurations }
#
#   # modules/hosts/ca.nix
#   { mkSystemManagerHost }:
#   mkSystemManagerHost {
#     hostName = "ca";
#     home = false;
#   }
args @ {
  inputs,
  pkgs,
  ...
}:
(import ./hostLib.nix args).mkHost {
  platformDir = "linux";
  buildSystem = {
    specialArgs,
    modules,
  }:
    inputs.system-manager.lib.makeSystemConfig {
      specialArgs =
        specialArgs
        // {
          inherit pkgs;
          system-manager = inputs.system-manager.packages.${pkgs.stdenv.hostPlatform.system}.default;
        };
      inherit modules;
    };
}
