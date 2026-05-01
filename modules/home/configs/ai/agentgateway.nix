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
    # uv's relocatable tool shims start with `exec "$(dirname "$(realpath "$0")")/python"`
    # to find the bundled python in ~/.local/share/uv/python/<ver>/bin. Without coreutils
    # on PATH, realpath/dirname fail and the shim execs /python, killing stdio MCP targets.
    "${pkgs.coreutils}/bin"
    "${config.home.profileDirectory}/bin"
    "${config.home.homeDirectory}/.local/bin"
    "/opt/homebrew/bin"
    "/usr/local/bin"
    "/usr/bin"
    "/bin"
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
          #
          # Also source opah's cached 1Password secrets if present, so stdio
          # MCP subprocesses (hubble, splunk, sentry, etc.) inherit credentials
          # that are otherwise only loaded into interactive fish sessions.
          ProgramArguments = [
            "/bin/sh"
            "-c"
            ''
              export SSH_AUTH_SOCK="$(/bin/launchctl getenv SSH_AUTH_SOCK)"

              opah_cache="${config.xdg.cacheHome}/fish/opah/secrets.fish"
              if [ -r "$opah_cache" ]; then
                # Translate `set -gx KEY 'val'` (fish) to `export KEY='val'` (sh),
                # preserving single-quote quoting so values containing shell
                # metacharacters (|, &, ;, =, etc.) don't get interpreted by eval.
                # Fish and sh single-quote literals are compatible as long as the
                # value contains no single quotes or backslashes, which opah's
                # cache currently never produces.
                # BSD sed (always present at /usr/bin/sed on darwin) handles this.
                eval "$(/usr/bin/sed -nE "s/^set -gx ([A-Za-z_][A-Za-z0-9_]*) '(.*)'$/export \1='\2'/p" "$opah_cache")"
              fi

              exec ${lib.getExe my.pkgs.agentgateway} -f ${configPath}
            ''
          ];

          EnvironmentVariables = {
            PATH = path;
            # Force-enable the Python GIL for all stdio Python MCP subprocesses.
            # Non-freethreaded Python 3.13 builds crash on startup with
            # "Fatal Python error: config_read_gil: Disabling the GIL is not supported"
            # if PYTHON_GIL=0 leaks in from a user shell (e.g. via direnv/.envrc).
            PYTHON_GIL = "1";
          };
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
          Environment = [
            "PATH=${path}"
            # See darwin block above: force-enable GIL for Python MCP subprocesses.
            "PYTHON_GIL=1"
          ];
          LimitNOFILE = 8192;
          Restart = "on-failure";
        };

        Install.WantedBy = ["default.target"];
      };
    })
  ];
}
