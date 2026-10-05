{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.tailscale;
  tailscale = lib.getExe pkgs.tailscale;
  tailscaled = lib.getExe' pkgs.tailscale "tailscaled";
in {
  options.services.tailscale = {
    enable = lib.mkEnableOption "Tailscale";

    port = lib.mkOption {
      type = lib.types.port;
      default = 41641;
    };

    permitCertUid = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "User allowed to fetch TLS certs from tailscaled.";
    };

    setFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["--accept-dns=true" "--advertise-exit-node"];
      description = "Prefs applied with `tailscale set` after every start; unlisted prefs keep their stored value.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale.setFlags = lib.mkBefore ["--auto-update=false"];

    environment.systemPackages = [pkgs.tailscale];

    # Same unit name as Ubuntu's package, so this /etc unit shadows /usr/lib's and the state file is reused.
    systemd.services = {
      tailscaled = {
        enable = true;
        description = "Tailscale node agent";
        wantedBy = ["system-manager.target"];

        # PartOf on tailscale-set propagates stop but not start; this re-applies prefs on every start.
        wants = ["network-pre.target" "tailscale-set.service"];
        after = ["network-pre.target" "NetworkManager.service" "systemd-resolved.service"];

        # The package wrapper already provides iproute2/iptables; modprobe is for the v6nat check.
        path = [pkgs.kmod];

        environment = lib.optionalAttrs (cfg.permitCertUid != null) {
          TS_PERMIT_CERT_UID = cfg.permitCertUid;
        };

        serviceConfig = {
          Type = "notify";
          ExecStart = "${tailscaled} --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock --port=${toString cfg.port}";
          ExecStopPost = "${tailscaled} --cleanup";
          Restart = "on-failure";
          RuntimeDirectory = "tailscale";
          RuntimeDirectoryMode = "0755";
          StateDirectory = "tailscale";
          StateDirectoryMode = "0700";
          CacheDirectory = "tailscale";
          CacheDirectoryMode = "0750";
        };
      };

      tailscale-set = {
        enable = true;
        description = "Apply Tailscale prefs";
        wantedBy = ["system-manager.target"];
        requires = ["tailscaled.service"];
        after = ["tailscaled.service"];
        partOf = ["tailscaled.service"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = lib.escapeShellArgs ([tailscale "set"] ++ cfg.setFlags);
        };
      };
    };
  };
}
