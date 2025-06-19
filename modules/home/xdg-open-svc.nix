{
  flake,
  pkgs,
  lib,
  ...
}: let
  local =
    (flake.inputs.upstream or flake).packages.${pkgs.system} or {};
in {
  launchd.agents.xdg-open-svc = {
    enable = true;
    config = {
      ProgramArguments = [
        "${lib.getExe local.xdg-open-svc}"
      ];

      KeepAlive = true;
      RunAtLoad = true;
      # StandardOutPath = cfg.logFile;
      # StandardErrorPath = cfg.logFile;
    };
  };
}
