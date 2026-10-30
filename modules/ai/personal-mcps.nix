{
  mkUserModule,
  config,
  lib,
  my,
  pkgs,
  ...
}:
mkUserModule {
  name = "personal-mcps";
  needs = ["ai"];
  default = false;

  home = {
    fishSecrets = {
      HOMEKIT_MCP_TOKEN = "op://Services/HomeBar MCP/credential";
      RACHIO_ACCESS_TOKEN = "op://Services/Rachio MCP/credential";
      TAILSCALE_API_KEY = "op://Services/Tailscale API/credential";
    };

    programs.mcp.servers = {
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
        command = lib.getExe my.pkgs.quicken-mac-mcp;
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
        env.TAILSCALE_TAILNET = "sully.org";
      };
      tripsy = {
        command = lib.getExe' my.pkgs.tripsy-cli "tripsy-mcp";
      };
    };
  };
}
