{
  flake,
  inputs,
  lib,
  pkgs,
  system-manager,
  ...
}: let
  caddyConfigDir = "/etc/caddy";
  caddyDataDir = "/var/lib/caddy";
  caddyLogDir = "/var/log/caddy";

  inherit (flake.packages.x86_64-linux) caddy-custom;

  opnix = inputs.opnix.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # opnix reads this token at boot and writes secrets to disk. Bootstrap once
  # on the host with: sudo opnix token set
  opnixTokenFile = "/etc/opnix-token";
  opnixOutputDir = "/var/lib/opnix";

  # Cloudflare DNS-01 token for the *.sully.org wildcard cert. Lives on tmpfs
  # so it is re-fetched (never persisted) on every boot. Caddy reads it via the
  # {file.*} placeholder in the Caddyfile.
  cloudflareTokenPath = "/run/secrets/caddy/cloudflare-token";

  opnixConfig = (pkgs.formats.json {}).generate "opnix-secrets.json" {
    secrets = [
      {
        path = cloudflareTokenPath;
        reference = "op://Services/Cloudflare DNS Token/credential";
        owner = "caddy";
        group = "caddy";
        mode = "0400";
      }
    ];
  };

  smService = attrs:
    lib.recursiveUpdate {
      enable = true;
      wantedBy = ["system-manager.target"];
    }
    attrs;
in {
  imports = [
    flake.modules.system-manager.common
    ./options.nix
  ];

  config = {
    environment = {
      etc = lib.mapAttrs (_: v: v // {replaceExisting = true;}) {
        "sudoers.d/10-nix-commands".source = pkgs.replaceVars ./files/sudoers-nix {
          systemManager = "${system-manager}/bin/system-manager";
          lix = lib.getExe pkgs.lix;
        };

        "sudoers.d/dsully".source = pkgs.replaceVars ./files/sudoers-dsully {
          liquidctl = lib.getExe pkgs.liquidctl;
        };

        "sudoers.d/vopono".source = ./files/sudoers-vopono;
        "sudoers.d/homebridge".source = ./files/sudoers-homebridge;
        "sudoers.d/netdata".source = ./files/sudoers-netdata;

        "caddy/Caddyfile".source = pkgs.replaceVars ./files/Caddyfile {
          logDir = caddyLogDir;
        };

        "doas.conf" = {
          source = ./files/doas.conf;
          mode = "0400";
        };

        "netplan/01-netcfg.yaml".source = ./files/01-netcfg.yaml;

        "ssh/sshd_config.d/10-local.conf".source = ./files/sshd-10-local.conf;

        "rsyncd.conf".source = ./files/rsyncd.conf;

        "samba/smb.conf".source = ./files/smb.conf;

        "udev/rules.d/71-liquidctl.rules".source = "${pkgs.liquidctl}/lib/udev/rules.d/71-liquidctl.rules";

        "modprobe.d/blacklist-dsully.conf".source = ./files/modprobe-blacklist-dsully.conf;
        "modprobe.d/i915.conf".source = ./files/modprobe-i915.conf;
        "modprobe.d/zfs.conf".source = ./files/modprobe-zfs.conf;

        "sysctl.d/90-local.conf".source = ./files/sysctl-90-local.conf;
        "sysctl.d/99-tailscale.conf".source = ./files/sysctl-99-tailscale.conf;

        "avahi/smb.service".source = ./files/avahi-smb.service;

        "default/homebridge".source = ./files/homebridge.default;

        "environment".source = ./files/environment;

        "cloudflared/config.yml".source = ./files/cloudflared-config.yml;

        "sanoid/sanoid.conf".source = ./files/sanoid.conf;

        "cockpit/cockpit.conf".source = ./files/cockpit.conf;
      };

      systemPackages =
        [caddy-custom]
        ++ (with pkgs; [
          fish
          liquidctl
          rsync
          samba
          system-manager
          vopono
        ]);
    };

    systemd.tmpfiles.rules = [
      "d ${caddyDataDir} 0750 caddy caddy -"
      "d ${caddyLogDir} 0750 caddy caddy -"
      "d ${opnixOutputDir} 0700 root root -"
    ];

    systemd.services = {
      opnix-secrets = smService {
        description = "Fetch secrets from 1Password via opnix";
        wants = ["network-online.target"];
        after = ["network-online.target" "nss-lookup.target"];
        before = ["caddy.service"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${opnix}/bin/opnix secret -token-file ${opnixTokenFile} -config ${opnixConfig} -output ${opnixOutputDir}";
        };
      };

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

      caddy = smService {
        description = "Caddy web server";
        documentation = ["https://caddyserver.com/docs/"];
        wants = ["network-online.target" "opnix-secrets.service"];
        after = ["network-online.target" "opnix-secrets.service"];
        serviceConfig = {
          Type = "notify";
          User = "caddy";
          Group = "caddy";
          ExecStartPre = "${lib.getExe caddy-custom} validate --config ${caddyConfigDir}/Caddyfile";
          ExecStart = "${lib.getExe caddy-custom} run --config ${caddyConfigDir}/Caddyfile --resume --environ";
          ExecReload = "${lib.getExe caddy-custom} reload --config ${caddyConfigDir}/Caddyfile --force";
          TimeoutStopSec = "5s";
          LimitNOFILE = 1048576;
          PrivateTmp = true;
          ProtectSystem = "full";
          AmbientCapabilities = "CAP_NET_BIND_SERVICE";
          ReadWritePaths = "${caddyDataDir} ${caddyLogDir}";
        };
      };

      rsync = smService {
        description = "rsync daemon";
        after = ["network.target"];
        serviceConfig = {
          Type = "forking";
          ExecStart = "${lib.getExe pkgs.rsync} --daemon";
          PIDFile = "/run/rsyncd.pid";
          Restart = "on-failure";
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
