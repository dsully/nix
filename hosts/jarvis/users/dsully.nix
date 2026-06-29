{
  ai,
  config,
  flake,
  inputs,
  lib,
  perSystem,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;
in {
  imports = [
    flake.homeModules.dsully
    flake.homeModules.ai
    flake.homeModules.meridian
    flake.homeModules.paste
    flake.homeModules.xdg-open-svc
    ../options.nix
  ];

  home = {
    activation = {
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
      ".huggingface".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/huggingface";
    };

    packages = with pkgs;
      [
        copilot-language-server
        meridian
        nix-output-monitor
        zls
        zuban
      ]
      ++ (with perSystem.self; [
        autorebase
      ]);
  };

  programs.uv.tool.packages = [
    "unifi-mcp-server"
  ];

  programs = {
    mcp.servers = {
      homekit = {
        type = "http";
        url = "http://127.0.0.1:5333/mcp";
        headers = {
          Authorization = "Bearer {env:HOMEKIT_MCP_TOKEN}";
        };
      };
      unifi = ai.muxWrap {
        command = "${config.home.homeDirectory}/.local/bin/unifi-mcp-server";
        env = {
          UNIFI_API_TYPE = "local";
          UNIFI_DEFAULT_SITE = "default";
          UNIFI_LOCAL_HOST = "10.0.0.1";
          UNIFI_LOCAL_VERIFY_SSL = "false";
        };
      };
    };

    opencode.extraPlugins = [
      "${pkgs.meridian}/lib/meridian/plugin/meridian.ts"
    ];

    onepassword-secrets.secrets = {
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

    topgrade = {
      settings = lib.mkMerge [
        {
          git = {
            repos = [
              "${config.home.homeDirectory}/src/*/"
              "${config.home.homeDirectory}/src/neovim/*/"
              "${config.home.homeDirectory}/src/dots/*/*/"
              "${config.home.homeDirectory}/src/nix/*/"
              "${config.home.homeDirectory}/src/rust/*/"
            ];
          };

          misc = {
            only = [
              "brew_formula"
              "brew_cask"
              "git_repos"
            ];
          };
        }
      ];
    };
  };

  nixpkgs.overlays = [flake.inputs.meridian.overlays.default];
}
