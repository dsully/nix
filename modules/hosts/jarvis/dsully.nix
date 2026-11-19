{
  config,
  lib,
  perSystem,
  pkgs,
  ...
}: {
  fishSecrets = {
    HOMEKIT_MCP_TOKEN = "op://Services/HomeBar MCP/credential";
    RACHIO_ACCESS_TOKEN = "op://Services/Rachio MCP/credential";
    TAILSCALE_API_KEY = "op://Services/Tailscale API/credential";
    XCODE_SIGN_IDENTITY = "op://Services/Xcode Home/credential";
  };

  home = {
    file = {
      ".huggingface".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/huggingface";
    };

    packages = with pkgs;
      [
        zls
      ]
      ++ (with perSystem.self; [
        autorebase
        tripsy-cli
      ]);

    sessionVariables = {
      SAFARI_PROFILE = "Personal";
    };
  };

  programs = {
    mcp.servers = {
      fastmail = {
        type = "http";
        url = "https://api.fastmail.com/mcp";
        enabled = false;
      };
      homekit = {
        type = "http";
        url = "http://127.0.0.1:5333/mcp";
        headers = {
          Authorization = "Bearer {env:HOMEKIT_MCP_TOKEN}";
        };
        enabled = false;
        stateless = true;
      };
      quicken = {
        command = lib.getExe perSystem.self.quicken-mac-mcp;
        env = {
          QUICKEN_ALLOW_WRITES = "1";
        };
        enabled = false;
        stateless = true;
      };
      rachio = {
        command = lib.getExe' pkgs.uv "uvx";
        args = ["rachio-mcp"];
        enabled = false;
        stateless = true;
      };
      tailscale = {
        command = lib.getExe' pkgs.bun "bunx";
        args = [
          "--package=@hexsleeves/tailscale-mcp-server"
          "tailscale-mcp-server"
        ];
        enabled = false;
        env = {
          TAILSCALE_TAILNET = "sully.org";
        };
      };
      tripsy = {
        command = lib.getExe' perSystem.self.tripsy-cli "tripsy-mcp";
      };
    };

    onepassword-secrets.secrets = {
      sshRSAPrivateKey = {
        reference = "op://Services/gateway/private key";
        path = ".ssh/id_rsa";
      };
    };

    pi-coding-agent = {
      settings.packages = [
        "npm:@gotgenes/pi-anthropic-auth"
      ];
    };

    topgrade = {
      settings = {
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
      };
    };
  };
}
