{
  config,
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

  arrService = name: group: let
    pkg = pkgs.${name};
    envPrefix = lib.toUpper name;
  in
    smService {
      description = "${pkg.meta.mainProgram} daemon";
      wants = ["network-online.target"];
      after = ["network-online.target" "vopono-daemon.service"];
      serviceConfig = {
        Type = "simple";
        # vopono.service is a dsully user unit, so systemd cannot order against
        # it. Poll the host forwarder until qBittorrent answers any HTTP response.
        ExecStartPre = "${lib.getExe pkgs.curl} -so /dev/null --max-time 5 --retry 60 --retry-delay 5 --retry-all-errors http://127.0.0.1:9091/";
        TimeoutStartSec = "10min";
        User = name;
        Group = group;
        UMask = "0002";
        ExecStart = "${lib.getExe pkg} -nobrowser -data=/var/lib/${name}/";
        TimeoutStopSec = 20;
        KillMode = "process";
        Restart = "on-failure";
        # The built-in updater would try to write into the read-only store.
        Environment = [
          "${envPrefix}__UPDATE__MECHANISM=External"
          "${envPrefix}__UPDATE__AUTOMATICALLY=false"
        ];
      };
    };

  tunnelId = "8ce51aaf-f033-42aa-88b6-002af8e4dec6";
  tunnelCreds = "/var/lib/opnix/cloudflared-${tunnelId}.json";

  cloudflaredConfig = (pkgs.formats.yaml {}).generate "cloudflared.yml" {
    tunnel = tunnelId;
    metrics = "0.0.0.0:2000";
    no-autoupdate = true;
    ingress = [
      {
        hostname = "seerr.sully.org";
        service = "http://localhost:5055";
      }
      {service = "http_status:404";}
    ];
  };
in {
  config = {
    modules.system = {
      opnix = {
        enable = true;
        secrets = [
          {
            path = tunnelCreds;
            reference = "op://Services/Cloudflare Tunnel/credential";
          }
        ];
      };

      caddy = {
        enable = true;
        caddyfile = ./files/Caddyfile;
      };

      beszel-agent = {
        enable = true;
        extraFilesystems = ["/bits/media" "/bits/stuff" "/ai/models"];
      };
    };

    environment = {
      etc = lib.mapAttrs (_: v: v // {replaceExisting = true;}) {
        "avahi/smb.service".source = ./files/avahi-smb.service;
        "cockpit/cockpit.conf".source = ./files/cockpit.conf;
        "default/homebridge".source = ./files/homebridge.default;
        "environment".source = ./files/environment;
        "modprobe.d/blacklist-dsully.conf".source = ./files/modprobe-blacklist-dsully.conf;
        "modprobe.d/i915.conf".source = ./files/modprobe-i915.conf;
        "modprobe.d/zfs.conf".source = ./files/modprobe-zfs.conf;
        "netplan/01-netcfg.yaml" = {
          source = ./files/01-netcfg.yaml;
          mode = "0600";
        };
        "samba/smb.conf".source = ./files/smb.conf;
        "sanoid/sanoid.conf".source = ./files/sanoid.conf;
        "sudoers.d/10-nix-commands".source = pkgs.replaceVars ./files/sudoers-nix {
          systemManager = "${system-manager}/bin/system-manager";
          lix = lib.getExe pkgs.lix;
        };
        "sudoers.d/dsully".source = pkgs.replaceVars ./files/sudoers-dsully {liquidctl = lib.getExe pkgs.liquidctl;};
        "sudoers.d/homebridge".source = ./files/sudoers-homebridge;
        "sudoers.d/netdata".source = ./files/sudoers-netdata;
        "sudoers.d/vopono".source = pkgs.replaceVars ./files/sudoers-vopono {
          ip = lib.getExe' pkgs.iproute2 "ip";
        };
        "sysctl.d/90-local.conf".source = ./files/sysctl-90-local.conf;
        "sysctl.d/99-tailscale.conf".source = ./files/sysctl-99-tailscale.conf;
        "udev/rules.d/71-liquidctl.rules".source = "${pkgs.liquidctl}/lib/udev/rules.d/71-liquidctl.rules";
      };

      systemPackages = with pkgs; [
        liquidctl
        rsync
        samba
        vopono
      ];
    };

    systemd.services = {
      # LoadCredential lets the DynamicUser read the root-only opnix file.
      cloudflared = smService {
        description = "Cloudflare Tunnel";
        wants = ["network-online.target"];
        requires = ["opnix-secrets.service"];
        after = ["network-online.target" "opnix-secrets.service"];
        serviceConfig = {
          Type = "simple";
          DynamicUser = true;
          AmbientCapabilities = ["CAP_NET_BIND_SERVICE"];
          CapabilityBoundingSet = ["CAP_NET_BIND_SERVICE"];
          LoadCredential = ["creds.json:${tunnelCreds}"];
          ExecStart = "${lib.getExe pkgs.cloudflared} tunnel --config ${cloudflaredConfig} run --credentials-file %d/creds.json";
          Restart = "on-failure";
          RestartSec = "5s";
          TimeoutStartSec = 0;
        };
      };

      liquidctl = smService {
        description = "Kraken AIO pump and fan curve";
        serviceConfig = let
          liquidctl = lib.getExe pkgs.liquidctl;
        in {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = [
            "${liquidctl} initialize all"
            "${liquidctl} --match kraken set pump speed 90"
            "${liquidctl} --match kraken set fan speed 20 30 30 50 34 80 40 90 50 100"
          ];
          # The USB device can enumerate after the unit starts at boot.
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };

      # vopono writes its own hosts and nsswitch.conf ("hosts: files dns") into
      # /etc/netns/vpn-u1000/, and `ip netns exec` binds them over /etc. That
      # hosts file lacks this machine's name, so every port-forward callback
      # (`sudo -u dsully qbit-port-update`, ~45s) logs "unable to resolve host".
      # Re-add the name whenever vopono rewrites the file; triggered by the
      # vopono-netns-hosts path unit below. The grep makes our own write a no-op.
      vopono-netns-hosts = smService {
        description = "Add hostname to vopono netns hosts file";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "vopono-netns-hosts" ''
            f=/etc/netns/vpn-u1000/hosts
            [ -f "$f" ] || exit 0
            read -r host < /etc/hostname
            ${lib.getExe pkgs.gnugrep} -qw -- "$host" "$f" || echo "127.0.1.1 $host" >> "$f"
          '';
        };
      };

      # ZFS snapshot automounts under .zfs/snapshot never expire on this
      # kernel/ZFS pair (zfs_expire_snapshot is ignored), so any walk through
      # .zfs leaves them mounted and sanoid-prune then fails with "dataset is
      # busy". Unmount idle ones before each prune; umount refuses busy mounts.
      zfs-snapshot-unmount = smService {
        description = "Unmount idle ZFS snapshot automounts before pruning";
        wantedBy = ["sanoid-prune.service" "system-manager.target"];
        before = ["sanoid-prune.service"];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "zfs-snapshot-unmount" ''
            ${lib.getExe' pkgs.util-linux "findmnt"} -rn -t zfs -o TARGET \
              | ${lib.getExe pkgs.gnugrep} '/\.zfs/snapshot/' \
              | while read -r m; do ${lib.getExe' pkgs.util-linux "umount"} "$m" || true; done
          '';
        };
      };

      vopono-daemon = smService {
        description = "Vopono root daemon";
        wants = ["network-online.target"];
        after = ["network-online.target"];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${lib.getExe pkgs.vopono} daemon";
          # A restart here drops the socket that a running `vopono exec` client
          # holds. The client then falls back to sudo, which names the namespace
          # "vpn" instead of "vpn-u1000" and takes the next free 10.200.x.0/24
          # subnet, so qBittorrent binds to a missing interface and the host
          # forwarder points at the wrong address. try-restart puts the client
          # back on the daemon path; it does nothing when the unit is inactive,
          # so boot is unaffected. Use the host systemctl, which matches the
          # running manager.
          ExecStartPost = "-/bin/systemctl --user --machine=dsully@.host try-restart vopono.service";
          # The name takes two spellings: "vpn-u1000" through the daemon,
          # "vpn" through the sudo fallback.
          ExecStopPost = "-/bin/sh -c 'for ns in vpn-u1000 vpn; do /sbin/ip link delete \"$ns\"_s 2>/dev/null; /sbin/ip netns delete \"$ns\" 2>/dev/null; done; true'";
          Restart = "on-failure";
          RestartSec = "2s";
          Environment = [
            "RUST_LOG=info"
            # Nix helpers must precede the Ubuntu directories. Ubuntu's
            # /usr/bin/wg (1.0.20250521) fails openat() on every regular file
            # ("fopen: Permission denied"), so `wg setconf` silently skips the
            # [Peer] block. The tunnel then has no handshake, natpmpc gets no
            # answer, and vopono aborts with a misleading "server does not
            # support port forwarding".
            "PATH=${lib.makeBinPath [pkgs.wireguard-tools pkgs.iproute2 pkgs.libnatpmp]}:/usr/sbin:/usr/bin:/sbin:/bin"
          ];
        };
      };

      sonarr = arrService "sonarr" "media";
      radarr = arrService "radarr" "media";
      prowlarr = arrService "prowlarr" "prowlarr";

      beszel-hub = smService {
        description = "Beszel hub";
        wants = ["network-online.target"];
        after = ["network-online.target"];
        serviceConfig = {
          Type = "simple";
          User = "beszel";
          ExecStart = "${lib.getExe' pkgs.beszel "beszel-hub"} serve --http 0.0.0.0:8090 --dir /opt/beszel/beszel_data";
          Restart = "always";
          RestartSec = "5s";
        };
      };

      # Docker container stats read /var/run/docker.sock.
      beszel-agent.serviceConfig.SupplementaryGroups = ["docker"];

      smbd = smService {
        description = "Samba SMB daemon";
        after = ["network-online.target"];
        wants = ["network-online.target"];
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
        after = ["network-online.target"];
        wants = ["network-online.target"];
        serviceConfig = {
          Type = "notify";
          ExecStart = "${pkgs.samba}/bin/nmbd --foreground --no-process-group";
          Restart = "on-failure";
        };
      };

      # Runs from the uv-managed .venv symlink (not the cache-hash path, which
      # changes on `uv sync`). Must run as ${config.system.userName} since the
      # venv lives in that user's ~/.cache/uv.
      comfyui = smService {
        description = "ComfyUI";
        wants = ["network-online.target"];
        after = ["network-online.target"];
        serviceConfig = {
          Type = "simple";
          User = config.system.userName;
          SupplementaryGroups = ["media"];
          WorkingDirectory = "/ai/apps/ComfyUI";
          ExecStart = "/ai/apps/ComfyUI/.venv/bin/python main.py --gpu-only --listen 0.0.0.0 --enable-manager --cuda-malloc --enable-triton-backend --enable-assets";
          Restart = "on-failure";
          RestartSec = "5s";
          # PID1 (root) opens these before dropping to User=, so /var/log stays
          # root-owned and writable. truncate: resets the file on each start.
          StandardOutput = "truncate:/var/log/comfyui.log";
          StandardError = "truncate:/var/log/comfyui.log";
          Environment = [
            "HOME=/home/${config.system.userName}"
            "PATH=/run/system-manager/sw/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
          ];
        };
      };

      # invokeai-web resolves its root via INVOKEAI_ROOT, else the VIRTUAL_ENV
      # parent, else ~/invokeai. Launching the venv binary directly sets neither
      # env var, so without INVOKEAI_ROOT it would default to ~/invokeai and
      # ignore /ai/apps/InvokeAI/invokeai.yaml. Pin the root explicitly. Same
      # user/venv-symlink rationale as comfyui above.
      invokeai = smService {
        description = "InvokeAI";
        wants = ["network-online.target"];
        after = ["network-online.target"];
        serviceConfig = {
          Type = "simple";
          User = config.system.userName;
          WorkingDirectory = "/ai/apps/InvokeAI";
          ExecStart = "/ai/apps/InvokeAI/.venv/bin/invokeai-web";
          Restart = "on-failure";
          RestartSec = "5s";
          Environment = [
            "HOME=/home/${config.system.userName}"
            "INVOKEAI_ROOT=/ai/apps/InvokeAI"
            "PATH=/run/system-manager/sw/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
          ];
        };
      };
    };

    systemd.paths.vopono-netns-hosts = {
      wantedBy = ["system-manager.target"];
      pathConfig.PathChanged = "/etc/netns/vpn-u1000/hosts";
    };
  };
}
