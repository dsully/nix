{
  lib,
  my,
  ...
}
: {
  launchd.agents.xdg-open-svc = {
    enable = true;
    config = {
      ProgramArguments = [
        "${lib.getExe my.pkgs.xdg-open-svc}"
      ];

      KeepAlive = true;
      RunAtLoad = true;
      # StandardOutPath = cfg.logFile;
      # StandardErrorPath = cfg.logFile;
    };
  };
}
