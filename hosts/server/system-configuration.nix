{
  flake,
  lib,
  pkgs,
  system-manager,
  ...
}: let
  caddyConfigDir = "/etc/caddy";
  caddyDataDir = "/var/lib/caddy";
  caddyLogDir = "/var/log/caddy";

  inherit (flake.packages.x86_64-linux) caddy-custom;
in {
  imports = [
    flake.modules.system-manager.common
    ./options.nix
  ];

  config = {
    environment = {
      etc = {
        "sudoers.d/10-nix-commands".text =
          # bash
          ''
            Cmnd_Alias SYSTEM_MANAGER = ${system-manager}/bin/system-manager (build|switch) *
            Cmnd_Alias LIQUIDCTL = ${lib.getExe pkgs.liquidctl} (list|status)
            Cmnd_Alias NIX = ${lib.getExe pkgs.lix} *
            Cmnd_Alias VPN_CLEANUP = /sbin/ip link delete vpn_s, /sbin/ip link delete vpn_d, /sbin/ip netns delete vpn

            %admin ALL=(ALL:ALL) NOPASSWD:SETENV:LIQUIDCTL
            %admin ALL=(ALL:ALL) NOPASSWD:SETENV:NIX
            %admin ALL=(ALL:ALL) NOPASSWD:SETENV:SYSTEM_MANAGER
            %admin ALL=(ALL:ALL) NOPASSWD:VPN_CLEANUP

            Defaults:%sudo env_keep += "PATH SSH_AGENT_PID SSH_AUTH_SOCK TERM TERMINFO"
          '';

        "caddy/Caddyfile".text =
          # caddy
          ''
            {
              default_sni server.sully.org
              http_port 80
              https_port 443

              servers {
                protocols h1 h2
              }
            }

            *.sully.org {
              encode zstd gzip

              log {
                output file ${caddyLogDir}/access.log {
                  roll_size 64mb
                  roll_keep 5
                  roll_keep_for 720h
                }
              }

              tls {
                dns cloudflare {env.CLOUDFLARE_API_TOKEN}
              }

              @syncthing host syncthing.sully.org
              handle @syncthing {
                reverse_proxy https://127.0.0.1:8384 {
                  header_up Host syncthing.sully.org
                  header_up X-Forwarded-Proto https
                  transport http {
                    tls
                    tls_insecure_skip_verify
                  }
                }
              }

              @plex host plex.sully.org
              handle @plex {
                reverse_proxy 127.0.0.1:32400
              }

              @dl host dl.sully.org
              handle @dl {
                reverse_proxy http://localhost:9091 {
                  header_up Host 127.0.0.1:9091
                  header_up -Origin
                  header_up -Referer
                  header_down -content-security-policy
                  header_down -x-frame-options
                  header_down -x-webkit-csp
                  header_down -x-xss-protection
                }
              }

              @overseerr host overseerr.sully.org
              handle @overseerr {
                reverse_proxy 127.0.0.1:5055
              }

              @homebridge host homebridge.sully.org
              handle @homebridge {
                reverse_proxy 127.0.0.1:8581
              }

              @resilio host resilio.sully.org
              handle @resilio {
                reverse_proxy 127.0.0.1:8888 {
                  transport http {
                    tls
                    tls_insecure_skip_verify
                  }
                }
              }

              @radarr host radarr.sully.org
              handle @radarr {
                reverse_proxy 127.0.0.1:7878
              }

              @sonarr host sonarr.sully.org
              handle @sonarr {
                reverse_proxy 127.0.0.1:8989
              }

              @prowlarr host prowlarr.sully.org
              handle @prowlarr {
                reverse_proxy 127.0.0.1:9696
              }

              @subtitles host subtitles.sully.org
              handle @subtitles {
                reverse_proxy 127.0.0.1:6767
              }

              @stash host stash.sully.org
              handle @stash {
                reverse_proxy 127.0.0.1:9999
              }

              @scrypted host scrypted.sully.org
              handle @scrypted {
                reverse_proxy https://127.0.0.1:10443 {
                  header_up Host scrypted.sully.org
                  header_up X-Forwarded-Proto https
                  transport http {
                    tls
                    tls_insecure_skip_verify
                  }
                }
              }

              @breadboard host breadboard.sully.org
              handle @breadboard {
                reverse_proxy 127.0.0.1:4200
              }

              @captions host captions.sully.org
              handle @captions {
                reverse_proxy 127.0.0.1:1337
              }

              @comfy host comfy.sully.org
              handle @comfy {
                reverse_proxy 127.0.0.1:8188
              }

              @invoke host invoke.sully.org
              handle @invoke {
                reverse_proxy 127.0.0.1:9090
              }

              @pose host pose.sully.org
              handle @pose {
                reverse_proxy 127.0.0.1:5173
              }

              @sd host sd.sully.org
              handle @sd {
                reverse_proxy 127.0.0.1:7860
              }

              @train host train.sully.org
              handle @train {
                reverse_proxy 127.0.0.1:7861
              }
            }
          '';

        "doas.conf" = {
          text =
            # bash
            ''
              permit root
              permit keepenv persist dsully

              permit nopass dsully as root cmd apt-get args clean
              permit nopass dsully as root cmd apt-get args update
              permit nopass dsully as root cmd apt-get args dist-upgrade -y
              permit nopass dsully as root cmd apt-get args autoremove -y
              permit nopass dsully as root cmd /usr/bin/snap args refresh
            '';
          mode = "0400";
        };

        "netplan/01-netcfg.yaml".text =
          # yaml
          ''
            network:
              version: 2
              renderer: "networkd"
              ethernets:
                eth0:
                  accept-ra: true
                  addresses: ["10.0.0.100/24"]
                  dhcp4: false
                  dhcp6: false
                  match:
                    macaddress: 3c:8c:f8:60:18:c1
                  optional: false
                  routes:
                    - to: default
                      via: 10.0.0.1
                      metric: 100
                      on-link: true
                  set-name: eth0
          '';

        "rsyncd.conf".text =
          # ini
          ''
            uid = root
            gid = root
            use chroot = no
            syslog facility = user

            [bits]
              comment = bits
              dont compress = *.mp3 *.MP3 *.zip *.ZIP *.gz *.bz2 *.dmg *.iso *.mkv *.mp4 *.flac *.aac *.wmv
              hosts allow jarvis
              path = /bits/
              read only = yes
              reverse lookup yes

            [models]
              dont compress = *.gz *.tgz *.zip *.z *.rpm *.deb *.iso *.bz2 *.tbz *.safetensors *.ckpt
              hosts allow jarvis
              list = no
              path = /ai/models/
              read only = no
              reverse lookup yes
          '';

        "samba/smb.conf".text =
          # ini
          ''
            [global]
            workgroup = WORKGROUP
            server string = %h
            multicast dns register = no

            case sensitive = true

            vfs objects = fruit streams_xattr dirsort aio_pthread

            ea support = yes
            fruit:aapl = yes
            fruit:encoding = native
            fruit:locking = none
            fruit:model = RackMac
            fruit:metadata = stream
            fruit:posix_rename = yes
            fruit:veto_appledouble = no
            fruit:wipe_intentionally_left_blank_rfork = yes
            fruit:delete_empty_adfiles = yes
            fruit:nfs_aces = no

            aio_pthread:aio open = yes

            dns proxy = no
            name resolve order = host
            preferred master = no
            unix extensions = no
            domain master = no
            server signing = no
            strict locking = no
            strict sync = no
            use sendfile = yes
            aio read size = 1
            aio write size = 1

            panic action = /usr/share/samba/panic-action %d

            server role = standalone server
            passdb backend = tdbsam
            obey pam restrictions = yes
            unix password sync = yes
            passwd program = /usr/bin/passwd %u
            passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .
            pam password change = yes
            map to guest = bad user
            inherit permissions = yes

            load printers = no
            printing = bsd
            printcap name = /dev/null
            disable spoolss = yes

            unix extensions = no

            [ai]
            path = /ai
            comment = AI
            read only = no

            [bits]
            path = /bits
            comment = Bits
            read only = no
          '';
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

    systemd.services = {
      vopono-daemon = {
        enable = true;
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
        wantedBy = ["system-manager.target"];
      };

      caddy = {
        enable = true;
        description = "Caddy web server";
        documentation = ["https://caddyserver.com/docs/"];
        wants = ["network-online.target"];
        after = ["network-online.target"];
        serviceConfig = {
          Type = "notify";
          ExecStartPre = "${lib.getExe caddy-custom} validate --config ${caddyConfigDir}/Caddyfile";
          ExecStart = "${lib.getExe caddy-custom} run --config ${caddyConfigDir}/Caddyfile --resume --environ";
          ExecReload = "${lib.getExe caddy-custom} reload --config ${caddyConfigDir}/Caddyfile --force";
          TimeoutStopSec = "5s";
          LimitNOFILE = 1048576;
          PrivateTmp = true;
          ProtectSystem = "full";
          AmbientCapabilities = "CAP_NET_BIND_SERVICE";
          EnvironmentFile = "-/etc/caddy/env";
          ReadWriteDirectories = "${caddyDataDir} ${caddyLogDir}";
        };
        wantedBy = ["system-manager.target"];
      };

      rsync = {
        enable = true;
        description = "rsync daemon";
        after = ["network.target"];
        serviceConfig = {
          Type = "forking";
          ExecStart = "${lib.getExe pkgs.rsync} --daemon";
          PIDFile = "/run/rsyncd.pid";
          Restart = "on-failure";
        };
        wantedBy = ["system-manager.target"];
      };

      smbd = {
        enable = true;
        description = "Samba SMB daemon";
        after = ["network.target"];
        serviceConfig = {
          Type = "notify";
          ExecStart = "${pkgs.samba}/bin/smbd --foreground --no-process-group";
          ExecReload = "/bin/kill -HUP $MAINPID";
          LimitNOFILE = 16384;
          Restart = "on-failure";
        };
        wantedBy = ["system-manager.target"];
      };

      nmbd = {
        enable = true;
        description = "Samba NMB daemon";
        after = ["network.target"];
        serviceConfig = {
          Type = "notify";
          ExecStart = "${pkgs.samba}/bin/nmbd --foreground --no-process-group";
          Restart = "on-failure";
        };
        wantedBy = ["system-manager.target"];
      };
    };
  };
}
