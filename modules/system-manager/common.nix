{
  config,
  lib,
  ...
}: let
  formatValue = v:
    if builtins.isList v
    then lib.concatStringsSep " " v
    else if builtins.isBool v
    then
      (
        if v
        then "true"
        else "false"
      )
    else toString v;

  nixConfContent = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (k: v: "${k} = ${formatValue v}") config.system.nixSettings
  );
in {
  imports = [
    ../common/nix.nix
  ];

  environment.etc."nix/nix.conf".text = nixConfContent;
}
