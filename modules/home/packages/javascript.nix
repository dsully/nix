{
  config,
  lib,
  pkgs,
  ...
}: let
  bunInstallPath = "${config.home.homeDirectory}/.bun";

  installScript =
    lib.concatMapStringsSep "\n" (pkg: ''
      BUN_INSTALL="${bunInstallPath}" ${lib.getExe pkgs.bun} install -g "${pkg}" >/dev/null 2>&1 || echo "Warning: Failed to install ${pkg}"
    '')
    config.packageTools.javascript;
in {
  options.packageTools.javascript = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    apply = lib.unique;
  };

  config = lib.mkIf (config.packageTools.javascript != [] && pkgs.stdenv.isDarwin) {
    home = {
      sessionVariables.BUN_INSTALL = bunInstallPath;
      sessionPath = ["${bunInstallPath}/bin"];
      activation.npmTools = lib.hm.dag.entryAfter ["writeBoundary" "installPackages"] ''
        ${installScript}
      '';
    };
  };
}
