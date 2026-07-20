{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.headroom;
  claudeCodeCfg = cfg.integrations.claudeCode;

  claudeProxyUrl = "http://${claudeCodeCfg.host}:${toString claudeCodeCfg.port}";

  environment = {
    HEADROOM_INTERCEPT_ENABLED = "1";
    HEADROOM_CODE_AWARE_ENABLED = "1";
    HEADROOM_PORT = "${claudeCodeCfg.port}";
  };

  # --disable-kompress is a deliberate behavior choice; --no-telemetry is the only
  # telemetry guard on the proxy path (services exec the raw binary, so neither the
  # wrapper nor sessionVariables reach it). --mode/--host defaults are left to headroom.
  claudeProxyArgs =
    [
      "${config.xdg.binHome}/headroom"
      "proxy"
      "--host"
      claudeCodeCfg.host
      "--port"
      (toString claudeCodeCfg.port)
      "--disable-kompress"
      "--no-telemetry"
    ]
    ++ claudeCodeCfg.extraArgs;

  claudeLaunchWrapper = pkgs.writeShellScript "headroom-claude-code-proxy-launch" ''
    set -eu
    exec ${lib.escapeShellArgs claudeProxyArgs}
  '';

  # headroom isn't in nixpkgs; it's installed via `uv tool` (headroom-ai[all])
  # into xdg.binHome. Wrap the uv-managed binary (referenced by absolute path)
  # so telemetry stays off and `wrap claude` picks up our default flags.
  headroomBin = pkgs.writeShellApplication {
    name = "headroom";
    text = ''
      export HEADROOM_TELEMETRY="off"

      if [ "$#" -ge 2 ] && [ "$1" = "wrap" ] && [ "$2" = "claude" ]; then
        shift 2
        exec ${config.xdg.binHome}/headroom wrap claude --no-rtk --no-serena "$@"
      fi

      exec ${config.xdg.binHome}/headroom "$@"
    '';
  };
in {
  options.programs.headroom = {
    enable = lib.mkEnableOption "Headroom context optimization layer";

    integrations.claudeCode = {
      enable = lib.mkEnableOption "routing Claude Code through a dedicated Headroom proxy";

      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Host address for the Claude Code Headroom proxy to bind.";
      };

      port = lib.mkOption {
        type = lib.types.str;
        default = "8788";
        description = "Port for the Claude Code Headroom proxy to bind.";
      };

      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Additional arguments passed to `headroom proxy`.";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = !claudeCodeCfg.enable || config.programs.claude-code.enable;
            message = "programs.headroom.integrations.claudeCode.enable requires programs.claude-code.enable.";
          }
        ];

        home = {
          packages = [headroomBin];

          sessionVariables =
            environment
            // lib.optionalAttrs claudeCodeCfg.enable {
              ANTHROPIC_BASE_URL = lib.mkForce claudeProxyUrl;
            };
        };

        programs.uv.tool.packages = [
          "headroom-ai[all]"
        ];
      }

      (lib.mkIf (claudeCodeCfg.enable && pkgs.stdenv.isLinux) {
        systemd.user.services.headroom-claude-code-proxy = {
          Unit = {
            Description = "Headroom Claude Code optimization proxy";
            After = ["network-online.target"];
          };
          Install.WantedBy = ["default.target"];
          Service = {
            Environment = lib.mapAttrsToList (name: value: "${name}=${value}") environment;
            ExecStart = "${claudeLaunchWrapper}";
            Restart = "on-failure";
            RestartSec = 5;
          };
        };
      })

      (lib.mkIf (claudeCodeCfg.enable && pkgs.stdenv.isDarwin) {
        launchd.agents.headroom-claude-code-proxy = {
          enable = true;
          config = {
            ProgramArguments = ["${claudeLaunchWrapper}"];
            EnvironmentVariables = environment // {HEADROOM_EMBEDDER_RUNTIME = "pytorch_mps";};
            KeepAlive = {
              Crashed = true;
              SuccessfulExit = false;
            };
            ProcessType = "Background";
            RunAtLoad = true;
            ThrottleInterval = 5;
          };
          domain = lib.mkDefault "gui";
        };
      })
    ]
  );
}
