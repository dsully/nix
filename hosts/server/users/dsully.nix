{
  flake,
  lib,
  perSystem,
  pkgs,
  ...
}: {
  imports = [
    flake.homeModules.dsully
    flake.homeModules.ai
    flake.homeModules.copypaste
    ../options.nix
  ];

  home = {
    packages = with pkgs;
      [
        copilot-language-server
        nix-output-monitor
        pnpm
        vopono
      ]
      ++ (with perSystem.self; [
        autorebase
        zuban
      ]);
  };

  programs = {
    onepassword-secrets = {
      enable = true;
      secrets = {
        cachixAuthToken = {
          reference = "op://Services/Cachix/token";
          path = ".config/cachix/auth-token";
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

  systemd.user.services.cachix-watch-store = {
    Unit = {
      Description = "Cachix Store Watcher";
      After = ["network.target"];
    };
    Service = {
      Environment = "XDG_CACHE_HOME=%h/.cache";
      ExecStart = "${pkgs.writeShellScript "cachix-watch" ''
        export CACHIX_AUTH_TOKEN=$(cat ~/.config/cachix/auth-token)
        exec ${pkgs.cachix}/bin/cachix watch-store dsully
      ''}";
      Restart = "always";
      RestartSec = 10;
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
