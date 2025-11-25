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
        bacon
        copilot-language-server
        ghostscript_headless
        nix-output-monitor
        pnpm
        tectonic-unwrapped
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
}
