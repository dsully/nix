{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../common/nix.nix
  ];

  nix = lib.mkMerge [
    {
      settings =
        config.system.nixSettings
        // {
          # NixOS's config/nix.nix (imported by system-manager) appends
          # "https://cache.nixos.org/" via mkAfter and prepends the
          # cache.nixos.org public key as plain list defaults, both of which
          # would duplicate our already-configured entries. Override them with
          # mkOverride 0 (max priority) to prevent the concatenation.
          substituters = lib.mkOverride 0 config.system.nixSettings.substituters;
          trusted-public-keys = lib.mkOverride 0 config.system.nixSettings.trusted-public-keys;
        };
    }

    # https://lix.systems/add-to-config/
    (lib.mkIf (config.system.nixFlavor == "lix") {
      enable = true;
      package = pkgs.lixPackageSets.latest.lix;
    })
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
}
