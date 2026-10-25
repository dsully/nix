# nixpkgs' systemd-lib now reads systemd.defaultPath, which system-manager does not declare.
# Delete this file once numtide/system-manager#587 merges (eval then fails with "already declared").
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.systemd.defaultPath = lib.mkOption {
    type = with lib.types; listOf (oneOf [package str]);
    default = [];
    description = "Packages appended to the PATH of all services that keep enableDefaultPath.";
  };

  config.systemd.defaultPath = with pkgs; [coreutils findutils gnugrep gnused config.systemd.package];
}
