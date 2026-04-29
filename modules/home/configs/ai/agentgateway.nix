{
  aiLib,
  config,
  lib,
  my,
  pkgs,
  ...
}: let
  yamlFormat = pkgs.formats.yaml {};

  enabledMcpServers = lib.filter (name: !(aiLib.mcpServers.${name}.disabled or false)) (lib.attrNames aiLib.mcpServers);

  mcpTarget = name: server: {
    inherit name;
    stdio =
      {
        cmd = server.command;
      }
      // lib.optionalAttrs (server ? args) {
        inherit (server) args;
      }
      // lib.optionalAttrs (server ? env) {
        inherit (server) env;
      };
  };

  agentgatewayConfig = {
    binds = [
      {
        inherit (aiLib.agentgateway) port;
        listeners = [
          {
            routes = [
              {
                policies.cors = {
                  allowOrigins = ["*"];
                  allowHeaders = [
                    "mcp-protocol-version"
                    "content-type"
                    "cache-control"
                  ];
                  exposeHeaders = ["Mcp-Session-Id"];
                };

                backends = [
                  {
                    mcp.targets = lib.map (name: mcpTarget name aiLib.mcpServers.${name}) enabledMcpServers;
                  }
                ];
              }
            ];
          }
        ];
      }
    ];
  };

  agentgatewayConfigFile = pkgs.runCommand "agentgateway-config.yaml" {} ''
    printf '%s\n' '# yaml-language-server: $schema=https://agentgateway.dev/schema/config' > $out
    cat ${yamlFormat.generate "agentgateway-config.yaml" agentgatewayConfig} >> $out
  '';

  configPath = "${config.xdg.configHome}/agentgateway/config.yaml";
  path = lib.concatStringsSep ":" [
    "${pkgs.nodejs}/bin"
    "${config.home.profileDirectory}/bin"
    "${config.home.homeDirectory}/.local/bin"
  ];
in {
  config = lib.mkMerge [
    {
      xdg.configFile."agentgateway/config.yaml".source = agentgatewayConfigFile;
    }

    (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      launchd.agents.agentgateway = {
        enable = true;
        config = {
          Label = "localhost.agentgateway";
          ProgramArguments = [
            "${lib.getExe my.pkgs.agentgateway}"
            "-f"
            configPath
          ];

          EnvironmentVariables.PATH = path;
          KeepAlive = {
            Crashed = true;
            SuccessfulExit = false;
          };
          RunAtLoad = true;
          ProcessType = "Background";
          StandardOutPath = "${config.xdg.cacheHome}/agentgateway.log";
          StandardErrorPath = "${config.xdg.cacheHome}/agentgateway.log";
        };
      };
    })

    (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      systemd.user.services.agentgateway = {
        Unit.Description = "Agentgateway MCP proxy";

        Service = {
          ExecStart = "${lib.getExe my.pkgs.agentgateway} -f ${configPath}";
          Environment = "PATH=${path}";
          Restart = "on-failure";
        };

        Install.WantedBy = ["default.target"];
      };
    })
  ];
}
