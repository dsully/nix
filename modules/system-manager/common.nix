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

  # Shared sshd hardening + AcceptEnv (so jarvis can pass SSH_CLIENT_* paths,
  # consumed by the `tower` fish fn). Applies to every Linux host; Darwin hosts
  # get the equivalent via modules/darwin/common.nix. Takes effect only after
  # sshd is reloaded. NOTE: no Subsystem here -- the stock sshd_config already
  # defines `Subsystem sftp`, and a duplicate definition is fatal to sshd.
  environment.etc."ssh/sshd_config.d/10-local.conf" = {
    source = ./files/sshd-10-local.conf;
    replaceExisting = true;
  };
}
