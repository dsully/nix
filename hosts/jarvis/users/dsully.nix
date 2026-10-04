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
    flake.homeModules.paste
    flake.homeModules.unifi
    flake.homeModules.configs.rumdl
    flake.homeModules.xdg-open-svc
    ../options.nix
  ];

  fishSecrets = {
    HOMEKIT_MCP_TOKEN = "op://Services/HomeBar MCP/credential";
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
    };

    meridian.enable = false;

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

    opencode.enable = false;

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
