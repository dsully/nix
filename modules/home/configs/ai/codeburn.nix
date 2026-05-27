{
  config,
  lib,
  my,
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
}
