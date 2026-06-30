{
  config,
  inputs,
  lib,
  perSystem,
  pkgs,
  ...
}: let
  inherit (config.system) userName;

  homeDir = config.home.homeDirectory;
in {
  # Don't bother building fonts that I don't use.
  disabledModules = [
    "targets/darwin/copyapps.nix"
    "targets/darwin/default.nix"
    "targets/darwin/fonts.nix"
    "targets/darwin/keybindings.nix"
    "targets/darwin/search.nix"
  ];

  imports = [
    inputs.nix-index-database.homeModules.nix-index
    inputs.opnix.homeManagerModules.default
    ../common/nix.nix
    ./chsh
    ./colors.nix
    ./configs
    ./dotfiles.nix
    ./packages
  ];

  # In this flake: perSystem.self
  # In consuming flake: perSystem.upstream
  #
  # Debug: This will show what packages are available
  # packages = [
  #   (builtins.trace "Available packages: ${builtins.toJSON (builtins.attrNames (perSystem.upstream.self or perSystem.self))}")
  # ];
  _module.args.my.pkgs = pkgs.extend (
    _final: _prev:
      (perSystem.upstream or perSystem.self)
      // lib.optionalAttrs (inputs ? neovim-nightly-overlay) {
        inherit (inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}) neovim;
      }
  );

  home = {
    # See here what bumping this value impacts:
    # https://nix-community.github.io/home-manager/release-notes.xhtml
    stateVersion = "25.05";
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
      "iCloud" = lib.mkIf pkgs.stdenv.isDarwin {
        source = config.lib.file.mkOutOfStoreSymlink "${homeDir}/Library/Mobile Documents/com~apple~CloudDocs";
      };

      "Downloads" = lib.mkIf pkgs.stdenv.isDarwin {
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
      lib.optionalAttrs pkgs.stdenv.isDarwin {
        HOMEBREW_NO_ANALYTICS = "1";
        HOMEBREW_NO_ASK = "1";
        HOMEBREW_NO_COMPAT = "1";
        HOMEBREW_NO_ENV_HINTS = "1";
        HOMEBREW_NO_INSTALL_CLEANUP = "1";
        HOMEBREW_NO_REQUIRE_TAP_TRUST = "1";
      }
      // {
        XDG_STATE_HOME = "${config.home.homeDirectory}/.local/state";
      };
  };

  manual.manpages.enable = false;

  programs = {
    onepassword-secrets = {
      enable = true;
      secrets = {
        checkipMaxmind = {
          reference = "op://Services/MaxMind API/credential";
          path = ".config/checkip/maxmind-key";
          mode = "0600";
          group = config.system.primaryGroup;
        };
        checkipUrlscan = {
          reference = "op://Services/URLScan API/credential";
          path = ".config/checkip/urlscan-key";
          mode = "0600";
          group = config.system.primaryGroup;
        };
        zonedCloudflareToken = {
          reference = "op://Services/Cloudflare DNS Token/credential";
          path = ".config/zoned/cloudflare-token";
          mode = "0600";
          group = config.system.primaryGroup;
        };
        zonedCloudflareZoneId = {
          reference = "op://Services/Cloudflare DNS Token/zoneid";
          path = ".config/zoned/cloudflare-zone-id";
          mode = "0600";
          group = config.system.primaryGroup;
        };
      };
    };

    home-manager.enable = true;

    man = {
      enable = true;
      generateCaches = false;
    };

    nh = {
      enable = true;
      package = (perSystem.upstream or perSystem.self).nh;

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
}
