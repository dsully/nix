{
  config,
  flake,
  lib,
  perSystem,
  pkgs,
  ...
}: let
  cachixAuthTokenPath = ".config/cachix/auth-token";

  qbit-tools = builtins.getFlake "github:dsully/qbit-tools";
  qbit-tools-pkg = qbit-tools.packages.${pkgs.stdenv.hostPlatform.system}.default;

  vopono-config = "${config.home.homeDirectory}/.cache/vopono/wg.conf";
in {
  imports = [
    flake.homeModules.dsully
    flake.homeModules.ai
    flake.homeModules.copypaste
    qbit-tools.homeManagerModules.default
    ../options.nix
  ];

  home = {
    packages = with pkgs;
      [
        copilot-language-server
        iproute2
        nix-output-monitor
        pnpm
        qbittorrent-nox
        socat
        vopono
        zuban
      ]
      ++ (with perSystem.self; [
        autorebase
      ])
      ++ [
        qbit-tools.packages.${stdenv.hostPlatform.system}.default
      ];
  };

  programs = {
    onepassword-secrets = {
      enable = true;
      secrets = {
        cachixAuthToken = {
          reference = "op://Services/Cachix/token";
          path = cachixAuthTokenPath;
          mode = "0600";
          group = "dsully";
        };
        huggingFace = {
          reference = "op://Services/HuggingFace/credential";
          path = ".config/huggingface/token";
          mode = "0600";
          group = "dsully";
        };
        sshPrivateKey = {
          reference = "op://Services/server/private key";
          path = ".ssh/id_ed25519";
          mode = "0600";
          group = "dsully";
        };
        voponoConfig = {
          reference = "op://Services/ProtonVPN Tunnel/config";
          path = vopono-config;
          mode = "0640";
          group = "dsully";
        };
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
    stash-watcher.enable = true;

    syncthing = {
      enable = true;
      guiAddress = "0.0.0.0:8384";
    };
  };

  systemd.user.services = {
    cachix-watch-store = {
      Unit = {
        Description = "Cachix Store Watcher";
        After = ["network.target"];
      };
      Service = {
        ExecStart = "${pkgs.writeShellScript "cachix-watch" ''
          export CACHIX_AUTH_TOKEN=$(cat ~/${cachixAuthTokenPath})
          exec ${lib.getExe pkgs.cachix} watch-store dsully
        ''}";
        Restart = "always";
        RestartSec = 10;
      };
      Install = {
        WantedBy = ["default.target"];
      };
    };

    vopono = {
      Unit = {
        Description = "Vopono qBittorrent";
        Wants = ["network-online.target"];
        After = ["local-fs.target" "network-online.target" "nss-lookup.target" "vopono-daemon.service"];
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
          "--port-forwarding-callback=${qbit-tools-pkg}/bin/qbit-port-update"
          "'${lib.getExe pkgs.qbittorrent-nox} --webui-port=9091 --profile=/bits/media/torrents'"
        ];
        PrivateTmp = false;
        Restart = "on-failure";
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
