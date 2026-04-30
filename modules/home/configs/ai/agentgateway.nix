{
  aiLib,
  config,
  lib,
  my,
  pkgs,
  ...
}: let
  yamlFormat = pkgs.formats.yaml {};

  mcpServers = config.programs.mcp.servers;
  enabledMcpServers = lib.filter (name: !(mcpServers.${name}.disabled or false)) (lib.attrNames mcpServers);

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
                    mcp.targets = lib.map (name: mcpTarget name mcpServers.${name}) enabledMcpServers;
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
          # Wrap so SSH_AUTH_SOCK is populated at startup from the user's
          # launchd GUI session. launchd agents don't inherit it otherwise,
          # which breaks config hot-reload when targets reference ${env:SSH_AUTH_SOCK}
          # and also prevents stdio MCP subprocesses from using ssh-agent.
          ProgramArguments = [
            "/bin/sh"
            "-c"
            ''
              export SSH_AUTH_SOCK="$(/bin/launchctl getenv SSH_AUTH_SOCK)"
              exec ${lib.getExe my.pkgs.agentgateway} -f ${configPath}
            ''
          ];

          EnvironmentVariables.PATH = path;
          # launchd's default soft FD limit is 256; spawning many stdio MCP
          # subprocesses exhausts it and yields "Too many open files (os error 24)".
          SoftResourceLimits.NumberOfFiles = 8192;
          HardResourceLimits.NumberOfFiles = 8192;
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
          LimitNOFILE = 8192;
          Restart = "on-failure";
        };

        Install.WantedBy = ["default.target"];
      };
    })
  ];
}
