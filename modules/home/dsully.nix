{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (config.system) userName;

  homeDir = config.home.homeDirectory;
in {
  imports = [
    inputs.nix-index-database.homeModules.nix-index
    inputs.opnix.homeManagerModules.default
    ../common/nix.nix

    ./configs
    ./packages
  ];

  editorconfig = {
    enable = true;

    settings = {
      "*" = {
        charset = "utf-8";
        end_of_line = "lf";
        trim_trailing_whitespace = true;
        insert_final_newline = true;
        indent_style = "space";
      };
      "*.{js,json,jsonc,ts,nix,yml,yaml}" = {
        indent_size = 2;
        max_line_length = 160;
      };
      "*.{py,rs}" = {
        indent_size = 4;
        max_line_length = 160;
      };
      "*.go" = {
        indent_size = 8;
        indent_style = "tab";
      };
      "Makefile" = {
        indent_style = "tab";
      };
    };
  };

  home = {
    # See here what bumping this value impacts:
    # https://nix-community.github.io/home-manager/release-notes.xhtml
    stateVersion = "25.05";

    activation = {
      chezmoi = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary" "installPackages"] ''
        #!/bin/bash
        mkdir -p ~/.local/share

        if ! [ -d "$HOME/.local/share/chezmoi" ]; then
          ${lib.getExe pkgs.git} clone git@github.com:${userName}/dotfiles.git ~/.local/share/chezmoi

          ${lib.getExe pkgs.chezmoi} init --apply --exclude encrypted ${userName} < /dev/null
          ${lib.getExe pkgs.chezmoi} apply || true
        fi
      '';

      neovim = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary" "installPackages"] ''
        #!/bin/bash

        if ! [ -d "$HOME/.config/nvim" ]; then
            ${lib.getExe pkgs.git} clone git@github.com:${userName}/nvim.git ~/.config/nvim
        fi
      '';
    };

    file = {
      "iCloud" = lib.mkIf pkgs.stdenv.isDarwin {
        source = config.lib.file.mkOutOfStoreSymlink "${homeDir}/Library/Mobile Documents/com~apple~CloudDocs";
      };

      "Downloads" = lib.mkIf pkgs.stdenv.isDarwin {
        source = config.lib.file.mkOutOfStoreSymlink "${homeDir}/iCloud/Downloads";
      };

      "src".source = config.lib.file.mkOutOfStoreSymlink "${homeDir}/dev/src";

      ".huggingface".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/huggingface";
      ".ignore" = {
        force = true;
        text =
          lib.concatStringsSep "\n"
          [
            "*hammerspoon*"
            "Cargo.lock"
            "flake.lock"
            "Library/"
            "LICENSE"
            "Movies/"
            "package-lock.json"
            "uv.lock"
            "vendor/"
            "yarn.lock"
          ]
          + "\n";
      };

      ".npmrc" = {
        force = true;
        text = ''
          fund=false
          audit=false
        '';
      };
    };
  };

  nix.settings.auto-optimise-store = true;

  programs = {
    direnv = {
      nix-direnv.enable = true;
    };

    fish = {
      enable = true;
      plugins = [
        {
          name = "git";
          src = pkgs.fetchFromGitHub {
            owner = "jhillyerd";
            repo = "plugin-git";
            rev = "d6950214b6b2392d3dbb2cb670f2a5f240090038";
            hash = "sha256-0uEKw+7EXkf5u3p3hfthSfQO/2rr3wl35ela7P2vB0Q=";
          };
        }
        {
          name = "opah";
          src = pkgs.fetchFromGitHub {
            owner = "tbcrawford";
            repo = "opah.fish";
            rev = "fe12435c8ed1b39f4d667aec142a35bb5fbd4df7";
            hash = "sha256-SLtg5HA/ZSBhzbCEqmsMvvLrjk6FE1YbsDGeRVBuwag=";
          };
        }
      ];
    };

    home-manager.enable = true;

    nh = {
      enable = true;
      clean = {
        enable = true;
        extraArgs = "-d";
      };

      flake = "${config.xdg.configHome}/nix";
    };

    # generate index with: nix-index --filter-prefix '/bin/'
    nix-index = {
      enable = true;
      enableBashIntegration = false;
      enableZshIntegration = false;
      enableFishIntegration = false;
      symlinkToCacheHome = true;
    };

    nix-index-database.comma.enable = false;
  };

  targets.darwin.linkApps.enable = false;
  xdg.mime.enable = false;
}
