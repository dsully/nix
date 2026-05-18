{
  config,
  lib,
  my,
  pkgs,
  ...
}: let
  codeburnExe = lib.getExe my.pkgs.codeburn-rs;
in {
  home = {
    activation.codeburnSymlink = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ln $VERBOSE_ARG -sf ${codeburnExe} ${config.xdg.binHome}
    '';

    packages = [my.pkgs.codeburn-rs];
  };

  launchd.agents.codeburn-menubar = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [
        "${config.home.homeDirectory}/Applications/CodeBurnMenubar.app/Contents/MacOS/CodeBurnMenubar"
      ];

      EnvironmentVariables = {
        CODEBURN_BIN = codeburnExe;
        PATH = "${config.home.homeDirectory}/.local/state/nix/profile/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
      KeepAlive = true;
      RunAtLoad = true;
      ProcessType = "Interactive";
    };
  };

  packageTools.javascript =
    if pkgs.stdenv.hostPlatform.isDarwin
    then ["codeburn"]
    else [];
}
