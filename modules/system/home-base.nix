{
  config,
  inputs,
  lib,
  mkUserModule,
  pkgs,
  ...
}: let
  inherit (config.system) userName;

  homeDir = config.home.homeDirectory;
in
  mkUserModule {
    name = "home-base";

    # opnix defaults the group to "users" on Linux; hosts there use the user's own group.
    homeOptions.programs.onepassword-secrets.secrets = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        group = lib.mkDefault config.system.primaryGroup;
      });
    };

    home = {
      home = {
        enableNixpkgsReleaseCheck = false;

        activation = {
          neovim = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary" "installPackages"] ''
            #!/bin/bash

            if ! [ -d "$HOME/.config/nvim" ]; then
                ${lib.getExe pkgs.git} clone git@github.com:${userName}/nvim.git ~/.config/nvim
            fi
          '';
        };

        file = {
          "iCloud" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
            source = config.lib.file.mkOutOfStoreSymlink "${homeDir}/Library/Mobile Documents/com~apple~CloudDocs";
          };

          "Downloads" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
            source = config.lib.file.mkOutOfStoreSymlink "${homeDir}/iCloud/Downloads";
          };

          "src".source = config.lib.file.mkOutOfStoreSymlink "${homeDir}/dev/src";

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
        };

        language.base = "en_US.UTF-8";
        preferXdgDirectories = true;

        sessionPath = [config.xdg.binHome "${config.home.homeDirectory}/.cargo/bin"];

        sessionVariables =
          # These are here instead of homebrew.nix so they belong to home-manager instead of nix-darwin
          lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
            HOMEBREW_NO_ANALYTICS = "1";
            HOMEBREW_NO_ASK = "1";
            HOMEBREW_NO_COMPAT = "1";
            HOMEBREW_NO_ENV_HINTS = "1";
            HOMEBREW_NO_INSTALL_CLEANUP = "1";
          }
          // {
            XDG_STATE_HOME = "${config.home.homeDirectory}/.local/state";
          };
      };

      manual.manpages.enable = false;

      programs = {
        onepassword-secrets.enable = true;

        home-manager.enable = true;

        man = {
          enable = true;
          generateCaches = false;
        };

        nh = {
          enable = true;

          clean = {
            enable = true;
            extraArgs = "--no-direnv --no-gcroots";
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

      # nh shells out to `nix`, which isn't on the systemd user PATH.
      systemd.user.services.nh-clean = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        Service.Environment = ["PATH=/run/system-manager/sw/bin:${homeDir}/.nix-profile/bin:/usr/bin:/bin"];
      };

      targets.darwin.linkApps.enable = false;
      xdg = {
        enable = true;
        mime.enable = false;

        systemDirs = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
          data = [
            "${config.home.profileDirectory}/share"
            "/usr/share"
            "/usr/local/share"
          ];
        };
      };
    };
  }
