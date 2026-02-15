{
  config,
  lib,
  pkgs,
  ...
}: let
  dotfileDir = "${config.xdg.configHome}/nix/dotfiles";
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfileDir}/${path}";

  platformFunctions =
    if pkgs.stdenv.isDarwin
    then [
      "fix-locationd-permissions.fish"
      "open-reading-list-items-in-tabs.fish"
      "systemctl.fish"
    ]
    else [
      "disks.fish"
      "dmesg.fish"
      "systemctl.fish"
    ];

  platformDir =
    if pkgs.stdenv.isDarwin
    then "fish/functions-darwin"
    else "fish/functions-linux";
in {
  xdg.configFile =
    {
      "fish/conf.d" = {
        source = mkLink "fish/conf.d";
        recursive = true;
      };

      "fish/functions" = {
        source = mkLink "fish/functions";
        recursive = true;
      };

      "fish/completions" = {
        source = mkLink "fish/completions";
        recursive = true;
      };

      "fish/themes" = {
        source = mkLink "fish/themes";
        recursive = true;
      };
    }
    // lib.listToAttrs (
      map (name: {
        name = "fish/functions/${name}";
        value.source = config.lib.file.mkOutOfStoreSymlink "${dotfileDir}/${platformDir}/${name}";
      })
      platformFunctions
    );
}
