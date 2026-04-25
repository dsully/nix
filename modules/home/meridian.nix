{
  config,
  pkgs,
  ...
}: {
  home.file."${config.xdg.binHome}/opencode" = {
    force = true;
    source = "${pkgs.meridian}/libexec/meridian/opencode-wrapper";
  };
}
