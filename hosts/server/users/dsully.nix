{
  config,
  flake,
  lib,
  perSystem,
  pkgs,
  ...
}: let
  # inherit (flake.inputs.home-manager.lib.hm.dag) entryAfter;
  cachixAuthTokenPath = ".config/cachix/auth-token";
  homeDir = config.home.homeDirectory;
  voponoConfigPath = ".config/vopono/protonvpn-us-ca52.conf";
  voponoConfig = "${homeDir}/${voponoConfigPath}";

  # The namespace name depends on how vopono escalates. Through the root daemon
  # it appends "-u<uid>" (namespace_ownership::name_for_uid), so
  # --custom-netns-name=vpn yields "vpn-u1000"; dsully is uid 1000. Through the
  # sudo fallback daemon_uid is None and the name stays "vpn". vopono 1.0.1 has
  # no flag to refuse the fallback, so both names can exist and both need
  # cleanup and sudoers rules. ExecStartPre below keeps the daemon name the
  # only one in normal use. Session\Interface in qBittorrent.conf names the
  # WireGuard interface, which takes the same two spellings.
  voponoNetnsNames = ["vpn-u1000" "vpn"];

  # vopono unwinds the namespace only when it exits cleanly. A crash or a
  # SIGKILL leaves the netns, its veth pair, and the lock directory behind. The
  # names are fixed, so those leftovers collide with the next start: vopono
  # reuses the dead namespace, skips the port forwarder, and qBittorrent sees no
  # route out. A surviving namespace also holds its 10.200.x.0/24 subnet, so the
  # next start moves to the next free subnet. Delete them on every stop.
  # sudo matches the command path literally, so both spellings below need a rule
  # in hosts/server/files/sudoers-vopono. The pinned path is the real target;
  # /sbin/ip covers the window where `just system` and `just switch` disagree on
  # the store path. Every delete is idempotent, so running both is harmless.
  voponoCleanup = pkgs.writeShellScript "vopono-cleanup" ''
    for ip in ${lib.getExe' pkgs.iproute2 "ip"} /sbin/ip; do
      for ns in ${lib.concatStringsSep " " voponoNetnsNames}; do
        for link in "$ns"_s "$ns"_d "$ns"; do
          sudo -n "$ip" link delete "$link" 2>/dev/null || true
        done
        sudo -n "$ip" netns delete "$ns" 2>/dev/null || true
      done
    done
    for ns in ${lib.concatStringsSep " " voponoNetnsNames}; do
      rm -rf "${homeDir}/.config/vopono/locks/$ns"
    done
  '';

  # vopono assigns the host end of the veth pair 10.200.<subnet>.1 and the
  # namespace end 10.200.<subnet>.2 (netns.rs add_routing). The subnet is the
  # first free one, so it moves whenever a previous namespace outlives its run.
  # Read it from the host interface instead of pinning an address.
  voponoForward = pkgs.writeShellScript "vopono-qbit-forward" ''
    addr=$(${lib.getExe' pkgs.iproute2 "ip"} -4 -oneline addr show \
      | ${lib.getExe pkgs.gawk} '$2 ~ /^vpn(-u[0-9]+)?_d$/ {
          split($4, cidr, "/"); split(cidr[1], octet, ".");
          print octet[1] "." octet[2] "." octet[3] ".2"; exit
        }')

    if [ -z "$addr" ]; then
      echo "no vopono veth interface on the host" >&2
      exit 1
    fi

    exec ${lib.getExe pkgs.socat} TCP-LISTEN:9091,fork,reuseaddr "TCP:$addr:9091"
  '';
in {
  imports = [
    flake.homeModules.dsully
    flake.homeModules.ai
    flake.homeModules.copypaste
    flake.homeModules.unifi
    flake.homeModules.configs.rumdl
    ../options.nix
  ];

  home = {
    # activation.caddyEnv = entryAfter ["writeBoundary" "onepassword-secrets"] ''
    #   token_file="${homeDir}/.config/caddy/cloudflare-token"
    #
    #   if [ -f "$token_file" ]; then
    #     sudo mkdir -p /etc/caddy
    #     echo "CLOUDFLARE_API_TOKEN=$(cat "$token_file")" | sudo tee /etc/caddy/env > /dev/null
    #     sudo chmod 600 /etc/caddy/env
    #   fi
    # '';

    packages = with pkgs;
      [
        iproute2
        nix-output-monitor
        pnpm
        qbittorrent-nox
        rustic
        socat
        vopono
        zuban
      ]
      ++ (with perSystem.self; [
        qbit-port-update
        qbit-tools
      ]);

    sessionPath = ["/usr/local/cuda/bin"];

    sessionVariables = {
      CUDA_HOME = "/usr/local/cuda";
    };
  };

  xdg.configFile."vopono/config.toml".source = (pkgs.formats.toml {}).generate "vopono-config" {
    interface = "eth0";
    protocol = "Wireguard";
    provider = "Custom";
    custom = voponoConfig;
    custom_netns_name = "vpn";
  };

  programs = {
    fish = {
      completions."stash-tool" =
        builtins.readFile "${perSystem.self.qbit-tools}/share/fish/vendor_completions.d/stash-tool.fish";
    };

    meridian.enable = false;

    onepassword-secrets.secrets = {
      cachixAuthToken = {
        reference = "op://Services/Cachix/token";
        path = cachixAuthTokenPath;
        mode = "0600";
        group = config.system.primaryGroup;
      };
      huggingFace = {
        reference = "op://Services/HuggingFace/credential";
        path = ".config/huggingface/token";
        mode = "0600";
        group = config.system.primaryGroup;
      };
      sshPrivateKey = {
        reference = "op://Services/server/private key";
        path = ".ssh/id_ed25519";
        mode = "0600";
        group = config.system.primaryGroup;
      };
      voponoConfig = {
        reference = "op://Services/ProtonVPN Tunnel/config";
        path = voponoConfigPath;
        mode = "0600";
        group = config.system.primaryGroup;
      };
      mullvadAccount = {
        reference = "op://Services/Mullvad/username";
        path = ".mullvad-account";
        mode = "0600";
        group = config.system.primaryGroup;
      };
    };

    pi-coding-agent = {
      enable = true;
      settings.packages = [
        "git:github.com/paoloanzn/pi-black@v0.84.1-cc2.1.258.1"
      ];
    };

    topgrade = {
      settings = lib.mkMerge [
        {
          git = {
            repos = [
              "/ai/apps/automatic/extensions/*"
              "/ai/apps/stable-diffusion-webui/extensions/*"
            ];
          };

          misc = {
            only = ["deb_get" "system" "git_repos"];
          };
        }
      ];
    };
  };

  services = {
    syncthing = {
      enable = true;
      guiAddress = "0.0.0.0:8384";
    };
  };

  systemd.user.services = {
    stash-watcher = {
      Unit = {
        Description = "Stash file watcher";
        After = ["network.target"];
      };
      Service = {
        ExecStart = lib.getExe' perSystem.self.qbit-tools "stash-watcher";
        Restart = "always";
        RestartSec = 5;
      };
      Install = {
        WantedBy = ["default.target"];
      };
    };

    # cachix-watch-store = {
    #   Unit = {
    #     Description = "Cachix Store Watcher";
    #     After = ["network.target"];
    #   };
    #   Service = {
    #     ExecStart = "${pkgs.writeShellScript "cachix-watch" ''
    #       export CACHIX_AUTH_TOKEN=$(cat ~/${cachixAuthTokenPath})
    #       exec ${lib.getExe pkgs.cachix} watch-store dsully
    #     ''}";
    #     Restart = "always";
    #     RestartSec = 10;
    #   };
    #   Install = {
    #     WantedBy = ["default.target"];
    #   };
    # };

    vopono = {
      Unit = {
        Description = "Vopono qBittorrent";
        Wants = ["network-online.target"];
        X-SwitchMethod = "keep-old";
        # vopono-daemon.service is a system service, so cross-boundary ordering
        # does not work. ExecStartPre tests the daemon socket and RestartSec
        # retries until the daemon answers. The daemon restarts this unit from
        # its own ExecStartPost in hosts/server/system-configuration.nix.
        After = ["local-fs.target" "network-online.target" "nss-lookup.target"];
        # The old RestartSec (10s) equalled the default StartLimitIntervalSec,
        # so the rate limiter never tripped and a broken tunnel looped every
        # 10s forever without surfacing. With the backoff below, 12 starts take
        # about 40 minutes; after that the unit stays failed and is visible.
        StartLimitIntervalSec = 3600;
        StartLimitBurst = 12;
      };
      Service = {
        WorkingDirectory = "%h/.config/vopono";
        Environment = "RUST_LOG=info";
        ExecStartPre = [
          # An unclean shutdown (SIGKILL) leaves qBittorrent's single-instance
          # socket behind, which makes the next start silently exit 0 without
          # launching. Clear it so a crashed previous run can't wedge startup.
          "${pkgs.coreutils}/bin/rm -f /bits/media/torrents/qBittorrent/config/ipc-socket /bits/media/torrents/qBittorrent/config/lockfile"
          # Refuse to start without the daemon. vopono silently falls back to
          # sudo when the socket is gone, and that path names the namespace
          # "vpn" instead of "vpn-u1000", which leaves qBittorrent bound to an
          # interface that does not exist. Failing here makes Restart retry
          # with the backoff above until the daemon answers.
          "${pkgs.coreutils}/bin/test -S /run/vopono.sock"
        ];
        ExecStart = lib.concatStringsSep " " [
          "${lib.getExe pkgs.vopono}"
          "exec"
          "--interface=eth0"
          "--provider=custom"
          # No --forward here: it makes vopono spawn its own host-side socat on
          # 9091, which collides with vopono-qbit-forward.service below.
          "--protocol=Wireguard"
          "--custom-netns-name=vpn"
          "--custom=${voponoConfig}"
          "--no-killswitch"
          "--allow-host-access"
          "--custom-port-forwarding=protonvpn"
          "--port-forwarding-callback=${lib.getExe perSystem.self.qbit-port-update}"
          "'${lib.getExe pkgs.qbittorrent-nox} --webui-port=9091 --profile=/bits/media/torrents'"
        ];
        ExecStopPost = "-${voponoCleanup}";
        PrivateTmp = false;
        Restart = "on-failure";
        # Exponential backoff: 10s, then longer, capped at 5 minutes. A tunnel
        # that cannot come up no longer hammers the daemon every 10 seconds.
        RestartSec = "10s";
        RestartSteps = 6;
        RestartMaxDelaySec = "300s";
        # Give qBittorrent time to save resume data and remove its instance
        # socket on stop, rather than hitting the 90s default and getting SIGKILLed.
        TimeoutStopSec = "180s";
        # SIGINT makes the vopono daemon inject a 0x03 byte into the child PTY
        # instead of signalling it, so shutdown depends on qBittorrent reading
        # its terminal. SIGTERM takes the daemon's other branch, which calls
        # kill() on the child process group directly.
        KillSignal = "SIGTERM";
        Type = "simple";
      };
      Install = {
        WantedBy = ["default.target"];
      };
    };

    vopono-qbit-forward = {
      Unit = {
        Description = "qBittorrent port forwarder";
        # The target address only exists inside the vopono netns. Without
        # BindsTo this unit stayed active while that netns was gone, so port
        # 9091 accepted connections and then dropped them. It also kept the
        # port bound, which blocked the next vopono start.
        BindsTo = ["vopono.service"];
        After = ["vopono.service"];
      };
      Service = {
        ExecStart = "${voponoForward}";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      Install = {
        # Start and stop together with vopono, not with the session.
        WantedBy = ["vopono.service"];
      };
    };
  };
}
