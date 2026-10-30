{
  mkUserModule,
  lib,
  my,
  ...
}
:
mkUserModule {
  name = "xdg-open-svc";
  default = false;

  home = {
    launchd.agents.xdg-open-svc = {
      enable = true;
      waitForNixStore = false;
      config = {
        ProgramArguments = [
          "${lib.getExe my.pkgs.xdg-open-svc}"
        ];

        KeepAlive = true;
        RunAtLoad = true;
      };
      domain = lib.mkDefault "gui";
    };
  };
}
