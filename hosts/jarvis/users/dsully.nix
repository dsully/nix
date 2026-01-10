{
  config,
  flake,
  lib,
  perSystem,
  pkgs,
  ...
}: {
  imports = [
    flake.homeModules.dsully
    flake.homeModules.ai
    flake.homeModules.cachix-watch-store
    flake.homeModules.paste
    flake.homeModules.xdg-open-svc
    ../options.nix
  ];

  home = {
    packages = with pkgs;
      [
        copilot-language-server
        nix-output-monitor
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
        sshPrivateKey = {
          reference = "op://Services/jarvis/private key";
          path = ".ssh/id_ed25519";
          mode = "0600";
        };
        sshRSAPrivateKey = {
          reference = "op://Services/gateway/private key";
          path = ".ssh/id_rsa";
          mode = "0600";
        };
      };
    };

    topgrade = {
      settings = lib.mkMerge [
        {
          git = {
            repos = [
              "${config.home.homeDirectory}/src/*/"
              "${config.home.homeDirectory}/src/neovim/*/"
              "${config.home.homeDirectory}/src/neovim/dots/*/"
              "${config.home.homeDirectory}/src/nix/*/"
              "${config.home.homeDirectory}/src/rust/*/"
            ];
          };

          misc = {
            only = ["brew_formula" "brew_cask" "git_repos"];
          };
        }
      ];
    };
  };
}
