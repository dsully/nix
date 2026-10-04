{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.beszel-agent;
in {
  options.services.beszel-agent = {
    enable = lib.mkEnableOption "Beszel agent";

    listen = lib.mkOption {
      type = lib.types.str;
      default = "45876";
      description = "Port or address:port where the hub connects over SSH.";
    };

    extraFilesystems = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Mount points to report in addition to the root filesystem.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.beszel-agent = {
      enable = true;
      description = "Beszel agent";
      wantedBy = ["system-manager.target"];
      wants = ["network-online.target"];
      after = ["network-online.target"];
      environment =
        {
          LISTEN = cfg.listen;
          # The hub's public key; only a hub that holds the private half can connect.
          KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEsP7UephuqiTY4YJAkfuF+K/r2dFA/LAdi6kMZ3fyTW";
        }
        // lib.optionalAttrs (cfg.extraFilesystems != []) {
          EXTRA_FILESYSTEMS = lib.concatStringsSep "," cfg.extraFilesystems;
        };
      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        ExecStart = lib.getExe' pkgs.beszel "beszel-agent";
        StateDirectory = "beszel-agent";
        Restart = "always";
        RestartSec = "5s";
        # GPU stats need Ubuntu's /usr/bin/nvidia-smi.
        Environment = ["PATH=/run/system-manager/sw/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"];
      };
    };
  };
}
