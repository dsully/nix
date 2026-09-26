{
  ai,
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
    flake.homeModules.paste
    flake.homeModules.configs.rumdl
    flake.homeModules.xdg-open-svc
    ../options.nix
  ];

  fishSecrets = {
    HOMEKIT_MCP_TOKEN = "op://Services/HomeBar MCP/credential";
    UNIFI_API_KEY = "op://Services/UniFi API/credential";
  };

  home = {
    file = {
      ".huggingface".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/huggingface";
    };

    packages = with pkgs;
      [
        nix-output-monitor
        zls
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
        enabled = false;
        stateless = true;
      };
      unifi = ai.muxWrap {
        command = "${config.home.homeDirectory}/.local/bin/unifi-mcp-server";
        env = {
          UNIFI_API_TYPE = "local";
          UNIFI_DEFAULT_SITE = "default";
          UNIFI_LOCAL_HOST = "10.0.0.1";
          UNIFI_LOCAL_VERIFY_SSL = "false";
          UNIFI_SITE_MANAGER_ENABLED = "true";
        };
        enabled = false;
        stateless = true;
      };
    };

    meridian.enable = true;

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

    pi-coding-agent = {
      enable = true;
      settings.packages = [
        "git:github.com/paoloanzn/pi-black@v0.84.1-cc2.1.258.1"
      ];
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
}
