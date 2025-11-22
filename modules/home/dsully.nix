{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (config.system) userName;
in {
  imports = [
    inputs.nix-index-database.homeModules.nix-index
    ../common/chsh
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

      symlinks = ''
        #!/bin/bash

        if [ "$(uname -s)" == "Darwin" ]; then
            if ! [ -d "$HOME"/Downloads ] && ! [ -L "$HOME"/Downloads ]; then
                echo "Moving ~/Downloads to symlink into iCloud."

                /usr/bin/sudo rm -rf "$HOME"/Downloads
                ln -sf "$HOME"/iCloud/Downloads "$HOME"/Downloads
            fi

            if ! [ -L "$HOME"/iCloud ]; then
                ln -s "$HOME"/Library/Mobile\ Documents/com~apple~CloudDocs "$HOME"/iCloud
            fi
        fi

        if ! [ -L "$HOME"/src ]; then
            ln -sf "$HOME"/dev/src "$HOME"/src
        fi
      '';
    };

    defaultShell = pkgs.fish;

    file = {
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

  programs = {
    direnv = {
      nix-direnv.enable = true;
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
      enableFishIntegration = true;
      symlinkToCacheHome = true;
    };

    nix-index-database.comma.enable = false;
  };

  targets.darwin.linkApps.enable = false;
  xdg.mime.enable = false;
}
