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
    inputs.direnv-instant.homeModules.direnv-instant
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
  _module.args.my.pkgs = pkgs.extend (_final: _prev: (perSystem.upstream or perSystem.self));

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
      neovim = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary" "installPackages"] ''
        #!/bin/bash

        if ! [ -d "$HOME/.config/nvim" ]; then
            ${lib.getExe pkgs.git} clone git@github.com:${userName}/nvim.git ~/.config/nvim
        fi
      '';

      checkipConfig = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary" "onepassword-secrets"] ''
        maxmind_key="${homeDir}/.config/checkip/maxmind-key"
        urlscan_key="${homeDir}/.config/checkip/urlscan-key"

        if [ -f "$maxmind_key" ] && [ -f "$urlscan_key" ]; then
          cat > "${homeDir}/.checkip.yaml" <<YAML
        ---
        MAXMIND_LICENSE_KEY: $(cat "$maxmind_key")
        URLSCAN_API_KEY: $(cat "$urlscan_key")
        YAML
          chmod 600 "${homeDir}/.checkip.yaml"
        fi
      '';

      zonedConfig = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary" "onepassword-secrets"] ''
        token_file="${homeDir}/.config/zoned/cloudflare-token"
        zone_file="${homeDir}/.config/zoned/cloudflare-zone-id"

        if [ -f "$token_file" ] && [ -f "$zone_file" ]; then
          cat > "${homeDir}/.config/zoned/config.toml" <<TOML
        hostname = "${config.system.hostName}.sully.org"
        ${lib.optionalString pkgs.stdenv.isDarwin ''ssid = "sully"''}
        token = "$(cat "$token_file")"
        zoneid = "$(cat "$zone_file")"
        TOML
          chmod 600 "${homeDir}/.config/zoned/config.toml"
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
    };

    language.base = "en_US.UTF-8";

    sessionPath = ["${config.home.homeDirectory}/.local/bin" "${config.home.homeDirectory}/.cargo/bin"];

    sessionVariables = {
      # Silence direnv logging. Hook is invoked via vendor_conf.d/
      DIRENV_LOG_FORMAT = "";

      # Python
      PIP_CACHE_DIR = "${config.xdg.cacheHome}/pip";
      PIP_CONFIG_FILE = "${config.xdg.configHome}/pip/pip.conf";
      PIP_DISABLE_PIP_VERSION_CHECK = "1";
      PIP_REQUIRE_VIRTUALENV = "1";
      POETRY_CACHE_DIR = "${config.xdg.cacheHome}/poetry";
      POETRY_CONFIG_DIR = "${config.xdg.configHome}/poetry";
      POETRY_DATA_DIR = "${config.xdg.dataHome}/poetry";
      PYTHONDONTWRITEBYTECODE = "1";
      PTPYTHON_CONFIG_HOME = "${config.xdg.configHome}/ptpython";
      VIRTUAL_ENV_DISABLE_PROMPT = "1";
    };
  };

  manual.manpages.enable = false;

  nixpkgs.overlays = [
    (_final: prev: {
      python313Packages = prev.python313Packages.override {
        overrides = _pyFinal: pyPrev: {
          mcp = pyPrev.mcp.overrideAttrs (_old: {
            doCheck = false;
            postPatch = "";
          });
        };
      };
    })
  ];

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

    direnv = {
      enable = true;

      config = {
        global = {
          hide_env_diff = true;
          load_dotenv = true;
          strict_env = true;
          warn_timeout = "10s";
        };
        whitelist = {
          prefix = [
            "${homeDir}/dev/home"
            "${homeDir}/dev/work"
          ];
        };
      };

      nix-direnv = {
        enable = true;
      };
    };

    direnv-instant.enable = true;

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

    npm = {
      enable = true;

      settings = {
        audit = false;
        fund = false;
        prefix = "\${HOME}/.npm";
      };
    };
  };

  targets.darwin.linkApps.enable = false;
  xdg = {
    enable = true;
    mime.enable = false;
  };
}
