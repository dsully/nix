{
  config,
  lib,
  pkgs,
  ...
}: let
  dotfileDir = "${config.xdg.configHome}/nix/dotfiles";

  # mkOutOfStoreSymlink creates a nix store symlink pointing outside the store.
  # This breaks with `recursive = true` in sandbox builds because the target
  # doesn't exist in the sandbox, so the directory is created as a dangling
  # symlink instead of being expanded by lndir. Use the flake-relative path
  # (which copies into the store) for recursive directories instead.
  flakeDotfiles = ../../dotfiles;

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
      "vpn.fish"
    ];

  platformDir =
    if pkgs.stdenv.isDarwin
    then "fish/functions-darwin"
    else "fish/functions-linux";
in {
  xdg.configFile =
    {
      "fish/conf.d" = {
        source = "${flakeDotfiles}/fish/conf.d";
        recursive = true;
      };

      "fish/functions" = {
        source = "${flakeDotfiles}/fish/functions";
        recursive = true;
      };

      "fish/completions" = {
        source = "${flakeDotfiles}/fish/completions";
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

  # Live-symlinked scripts: edits to the working tree are reflected immediately,
  # no rebuild needed. Target must remain executable in the source tree.
  home.file."${config.xdg.binHome}/remove-unicode".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfileDir}/remove-unicode.py";
}
