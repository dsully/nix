{
  config,
  lib,
  pkgs,
  ...
}: let
  host = "127.0.0.1";
  port = 3456;
  baseUrl = "http://${host}:${toString port}";

  # `claude auth status` (the health check) shells out to /usr/bin/security to
  # read the Keychain, and Meridian spawns node by name. launchd hands us a
  # bare PATH (only SSH_AUTH_SOCK is inherited), so make all three reachable;
  # /usr/bin is a no-op on the Linux file-credential path.
  servicePath = "${lib.makeBinPath [
    config.programs.claude-code.package
    pkgs.nodejs
    pkgs.coreutils
  ]}:/usr/bin:/bin";

  environment = {
    # launchd inherits none of these; `claude auth status` derives the Keychain
    # account from $USER/$LOGNAME and reads config under $HOME, so set them.
    HOME = config.home.homeDirectory;
    USER = config.home.username;
    LOGNAME = config.home.username;

    MERIDIAN_HOST = host;
    MERIDIAN_PORT = toString port;
    # One shared proxy backs every OpenCode terminal; the plugin's per-session
    # affinity headers keep them from colliding, but the SDK pool must be wide
    # enough to serve them in parallel (default is 10).
    MERIDIAN_MAX_CONCURRENT = "24";
    MERIDIAN_WORKDIR = config.home.homeDirectory;
  };

  # OpenCode reads ANTHROPIC_BASE_URL/ANTHROPIC_API_KEY from its environment.
  # Scope them to OpenCode via a wrapper rather than home.sessionVariables, so
  # Claude Code (which also honors ANTHROPIC_BASE_URL) is left untouched.
  opencodeWrapper = pkgs.writeShellScript "opencode" ''
    export ANTHROPIC_API_KEY="meridian"
    export ANTHROPIC_BASE_URL="${baseUrl}"
    exec ${lib.getExe config.programs.opencode.package} "$@"
  '';
in {
  home.file."${config.xdg.binHome}/opencode" = {
    force = true;
    source = opencodeWrapper;
  };

  launchd.agents.meridian = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    enable = true;
    config = {
      Label = "localhost.meridian";
      ProgramArguments = [(lib.getExe pkgs.meridian)];
      EnvironmentVariables = environment // {PATH = servicePath;};
      RunAtLoad = true;
      KeepAlive = true;
      ProcessType = "Background";
      StandardOutPath = "${config.xdg.cacheHome}/meridian.log";
      StandardErrorPath = "${config.xdg.cacheHome}/meridian.log";
    };
  };

  systemd.user.services.meridian = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    Unit = {
      Description = "Meridian Claude Code SDK proxy";
      After = ["network.target"];
    };
    Service = {
      ExecStart = lib.getExe pkgs.meridian;
      Environment = lib.mapAttrsToList (n: v: "${n}=${v}") environment ++ ["PATH=${servicePath}"];
      Restart = "always";
      RestartSec = 2;
    };
    Install.WantedBy = ["default.target"];
  };
}
