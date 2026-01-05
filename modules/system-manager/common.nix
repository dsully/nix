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
      settings = config.system.nixSettings;
    }

    # https://lix.systems/add-to-config/
    (lib.mkIf (config.system.nixFlavor == "lix") {
      enable = true;
      package = pkgs.lixPackageSets.latest.lix;
    })
  ];

  nixpkgs.hostPlatform = "x86_64-linux";
}
