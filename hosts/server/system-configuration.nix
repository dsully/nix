{
  flake,
  lib,
  pkgs,
  system-manager,
  ...
}: let
  smService = attrs:
    lib.recursiveUpdate {
      enable = true;
      wantedBy = ["system-manager.target"];
    }
    attrs;
in {
  imports = [
    flake.modules.system-manager.common
    flake.modules.system-manager.caddy
    ./options.nix
  ];

  config = {
    services.caddy = {
      enable = true;
      caddyfile = ./files/Caddyfile;
    };

    environment = {
      etc = lib.mapAttrs (_: v: v // {replaceExisting = true;}) {
        "avahi/smb.service".source = ./files/avahi-smb.service;
        "cloudflared/config.yml".source = ./files/cloudflared-config.yml;
        "cockpit/cockpit.conf".source = ./files/cockpit.conf;
        "default/homebridge".source = ./files/homebridge.default;
        "doas.conf" = {
          source = ./files/doas.conf;
          mode = "0400";
        };
        "environment".source = ./files/environment;
        "modprobe.d/blacklist-dsully.conf".source = ./files/modprobe-blacklist-dsully.conf;
        "modprobe.d/i915.conf".source = ./files/modprobe-i915.conf;
        "modprobe.d/zfs.conf".source = ./files/modprobe-zfs.conf;
        "netplan/01-netcfg.yaml".source = ./files/01-netcfg.yaml;
        "samba/smb.conf".source = ./files/smb.conf;
        "sanoid/sanoid.conf".source = ./files/sanoid.conf;
        "sudoers.d/10-nix-commands".source = pkgs.replaceVars ./files/sudoers-nix {
          systemManager = "${system-manager}/bin/system-manager";
          lix = lib.getExe pkgs.lix;
        };
        "sudoers.d/dsully".source = pkgs.replaceVars ./files/sudoers-dsully {liquidctl = lib.getExe pkgs.liquidctl;};
        "sudoers.d/homebridge".source = ./files/sudoers-homebridge;
        "sudoers.d/netdata".source = ./files/sudoers-netdata;
        "sudoers.d/vopono".source = ./files/sudoers-vopono;
        "sysctl.d/90-local.conf".source = ./files/sysctl-90-local.conf;
        "sysctl.d/99-tailscale.conf".source = ./files/sysctl-99-tailscale.conf;
        "udev/rules.d/71-liquidctl.rules".source = "${pkgs.liquidctl}/lib/udev/rules.d/71-liquidctl.rules";
      };

      systemPackages = with pkgs; [
        fish
        liquidctl
        rsync
        samba
        system-manager
        vopono
      ];
    };

    systemd.services = {
      vopono-daemon = smService {
        description = "Vopono root daemon";
        wants = ["network-online.target"];
        after = ["network-online.target"];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${lib.getExe pkgs.vopono} daemon";
          ExecStopPost = "-/bin/sh -c '/sbin/ip link delete vpn_s 2>/dev/null; /sbin/ip netns delete vpn 2>/dev/null; true'";
          Restart = "on-failure";
          RestartSec = "2s";
          Environment = [
            "RUST_LOG=info"
            "PATH=/usr/sbin:/usr/bin:/sbin:/bin"
          ];
        };
      };

      smbd = smService {
        description = "Samba SMB daemon";
        after = ["network.target"];
        serviceConfig = {
          Type = "notify";
          ExecStart = "${pkgs.samba}/bin/smbd --foreground --no-process-group";
          ExecReload = "/bin/kill -HUP $MAINPID";
          LimitNOFILE = 16384;
          Restart = "on-failure";
        };
      };

      nmbd = smService {
        description = "Samba NMB daemon";
        after = ["network.target"];
        serviceConfig = {
          Type = "notify";
          ExecStart = "${pkgs.samba}/bin/nmbd --foreground --no-process-group";
          Restart = "on-failure";
        };
      };
    };
  };
}
