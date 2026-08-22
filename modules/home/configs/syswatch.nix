{
  lib,
  pkgs,
  ...
}: let
  tomlFormat = pkgs.formats.toml {};

  configFile = tomlFormat.generate "syswatch-config.toml" {
    default_tab = "overview";
    graph_fade = false;
    graph_style = "bars";
    theme = "nord";
    tick_ms = 1000;
    view = "full";
  };
in {
  config = {
    home.packages = with pkgs; [
      syswatch
    ];

    home.file = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      "Library/Application Support/syswatch/config.toml".source = configFile;
    };

    xdg.configFile = lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) {
      "syswatch/config.toml".source = configFile;
    };
  };
}
