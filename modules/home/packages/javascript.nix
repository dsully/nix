{
  config,
  lib,
  pkgs,
  ...
}: let
  installScript =
    lib.concatMapStringsSep "\n" (pkg: ''
      ${lib.getExe pkgs.bun} install -g "${pkg}" || echo "Warning: Failed to install ${pkg}"
    '')
    config.packageTools.npmPackages;
in {
  options.packageTools.npmPackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    apply = lib.unique;
  };

  config = lib.mkIf (config.packageTools.npmPackages != [] && pkgs.stdenv.isDarwin) {
    home.sessionPath = ["$HOME/.bun/bin"];

    home.activation.npmTools = lib.hm.dag.entryAfter ["writeBoundary" "installPackages"] ''
      ${installScript}
    '';
  };
}
