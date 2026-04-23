{
  config,
  flake,
  lib,
  perSystem,
  pkgs,
  ...
}: let
  inherit (flake.inputs.home-manager.lib.hm.dag) entryAfter;

  cachixAuthTokenPath = ".config/cachix/auth-token";
  homeDir = config.home.homeDirectory;
  vopono-config = "${homeDir}/.cache/vopono/wg.conf";
in {
  imports = [
    flake.homeModules.dsully
    flake.homeModules.ai
    flake.homeModules.meridian
    flake.homeModules.copypaste
    ../options.nix
  ];

  home = {
    activation.caddyEnv = entryAfter ["writeBoundary" "onepassword-secrets"] ''
      token_file="${homeDir}/.config/caddy/cloudflare-token"

      if [ -f "$token_file" ]; then
        sudo mkdir -p /etc/caddy
        echo "CLOUDFLARE_API_TOKEN=$(cat "$token_file")" | sudo tee /etc/caddy/env > /dev/null
        sudo chmod 600 /etc/caddy/env
      fi
    '';

    packages = with pkgs;
      [
        copilot-language-server
        iproute2
        meridian
        nix-output-monitor
        pnpm
        qbittorrent-nox
        socat
        vopono
        zuban
      ]
      ++ (with perSystem.self; [
        autorebase
        qbit-port-update
        qbit-tools
        turbo-commit
      ]);
  };

  nixpkgs.overlays = [flake.inputs.meridian.overlays.default];

  programs = {
    fish = {
      completions."stash-tool" =
        builtins.readFile "${perSystem.self.qbit-tools}/share/fish/vendor_completions.d/stash-tool.fish";

      interactiveShellInit =
        # fish
        ''
          if test -d /usr/local/cuda
              set -gx CUDA_HOME /usr/local/cuda
              fish_add_path --append "$CUDA_HOME/bin"
          end
        '';
    };

    opencode.extraPlugins = [
      "${pkgs.meridian}/lib/meridian/plugin/meridian.ts"
    ];

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
        path = vopono-config;
        mode = "0640";
        group = config.system.primaryGroup;
      };
      mullvadAccount = {
        reference = "op://Services/Mullvad/username";
        path = ".mullvad-account";
        mode = "0600";
        group = config.system.primaryGroup;
      };
      cloudflareApiToken = {
        reference = "op://Services/Cloudflare DNS Token/credential";
        path = ".config/caddy/cloudflare-token";
        mode = "0600";
        group = config.system.primaryGroup;
      };
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
        # Note: vopono-daemon.service is a system service so cross-boundary ordering
        # doesn't work. The user service relies on RestartSec to retry until the daemon is ready.
        After = ["local-fs.target" "network-online.target" "nss-lookup.target"];
      };
      Service = {
        WorkingDirectory = "%h/.config/vopono";
        Environment = "RUST_LOG=info";
        ExecStart = lib.concatStringsSep " " [
          "${lib.getExe pkgs.vopono}"
          "exec"
          "--interface=eth0"
          "--provider=custom"
          "--forward=9091"
          "--protocol=Wireguard"
          "--custom-netns-name=vpn"
          "--custom=${vopono-config}"
          "--no-killswitch"
          "--allow-host-access"
          "--custom-port-forwarding=protonvpn"
          "--port-forwarding-callback=${lib.getExe perSystem.self.qbit-port-update}"
          "'${lib.getExe pkgs.qbittorrent-nox} --webui-port=9091 --profile=/bits/media/torrents'"
        ];
        PrivateTmp = false;
        Restart = "on-failure";
        RestartSec = "10s";
        Type = "simple";
      };
      Install = {
        WantedBy = ["default.target"];
      };
    };

    vopono-qbit-forward = {
      Unit = {
        Description = "qBittorrent port forwarder";
        After = ["vopono.service"];
      };
      Service = {
        ExecStart = "${lib.getExe pkgs.socat} TCP-LISTEN:9091,fork,reuseaddr TCP:10.200.1.2:9091";
        Restart = "on-failure";
      };
      Install = {
        WantedBy = ["default.target"];
      };
    };
  };
}
