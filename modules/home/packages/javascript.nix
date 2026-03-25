{
  config,
  lib,
  pkgs,
  ...
}: let
  installScript =
    lib.concatMapStringsSep "\n" (pkg: ''
      ${lib.getExe pkgs.bun} install -g "${pkg}" >/dev/null 2>&1 || echo "Warning: Failed to install ${pkg}"
    '')
    config.packageTools.javascript;
in {
  options.packageTools.javascript = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    apply = lib.unique;
  };

  config = lib.mkIf (config.packageTools.javascript != [] && pkgs.stdenv.isDarwin) {
    home.sessionPath = ["$HOME/.bun/bin"];

    home.activation.npmTools = lib.hm.dag.entryAfter ["writeBoundary" "installPackages"] ''
      ${installScript}
    '';
  };
}
