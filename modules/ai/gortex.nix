{
  config,
  lib,
  mkUserModule,
  my,
  pkgs,
  piPath,
  ...
}: let
  exe = lib.getExe my.pkgs.gortex;
  jsonFormat = pkgs.formats.json {};
in
  mkUserModule {
    name = "gortex";
    default = false;
    needs = ["pi"];

    home = {
      home = {
        packages = [my.pkgs.gortex];

        # Keys: https://github.com/gortexhq/pi#configure
        # A `gortex` entry in pi's mcp.json would replace this extension's server, so none is declared.
        file."${piPath}/extensions/gortex.json".source = jsonFormat.generate "pi-gortex.json" {
          bin = exe;
          hook_mode = "enrich";
        };
      };

      # Not `gortex daemon install-service`: its plist pins the store path and a
      # PATH without the Nix profile, so upgrades break it and LSPs go missing.
      launchd.agents.gortex = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        # `gortex mcp` refuses to start without a running daemon.
        enable = true;

        config = {
          ProgramArguments = [exe "daemon" "start"];
          RunAtLoad = true;
          KeepAlive.SuccessfulExit = false;
          ProcessType = "Background";
          StandardOutPath = "${config.xdg.cacheHome}/gortex-daemon.log";
          StandardErrorPath = "${config.xdg.cacheHome}/gortex-daemon.log";
          EnvironmentVariables = {
            PATH = lib.concatStringsSep ":" [
              "${config.home.profileDirectory}/bin"
              "${config.home.homeDirectory}/.cargo/bin"
              "/run/current-system/sw/bin"
              "/usr/bin"
              "/bin"
              "/usr/sbin"
              "/sbin"
            ];

            # The socket lives under $XDG_CACHE_HOME/gortex; without these the
            # daemon falls back to ~/.gortex and `gortex mcp` can't find it.
            XDG_CACHE_HOME = config.xdg.cacheHome;
            XDG_CONFIG_HOME = config.xdg.configHome;
            XDG_DATA_HOME = config.xdg.dataHome;
          };
        };

        domain = lib.mkDefault "gui";
      };

      programs.pi-coding-agent.settings.packages = [
        "npm:pi-gortex"
      ];
    };
  }
