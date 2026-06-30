{
  config,
  lib,
  pkgs,
  ...
}: let
  bunInstallPath = "${config.home.homeDirectory}/.bun";
  npmCacheDir = "${config.xdg.cacheHome}/npm";

  installScript =
    lib.concatMapStringsSep "\n" (pkg: ''
      BUN_INSTALL="${bunInstallPath}" ${lib.getExe config.programs.bun.package} install -g "${pkg}" >/dev/null 2>&1 || echo "Warning: Failed to install ${pkg}"
    '')
    config.packageTools.javascript;
in {
  options.packageTools.javascript = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    apply = lib.unique;
  };

  config = lib.mkIf (config.packageTools.javascript != [] && pkgs.stdenv.isDarwin) {
    programs = {
      bun.enable = true;

      npm = {
        enable = true;
        settings = {
          audit = false;
          cache = npmCacheDir;
          fund = false;
          prefix = npmCacheDir;
        };
      };
    };

    home = {
      activation.npmTools = lib.hm.dag.entryAfter ["writeBoundary" "installPackages"] ''
        ${installScript}
      '';

      sessionPath = [
        "${bunInstallPath}/bin"
        "${npmCacheDir}/bin"
      ];

      sessionVariables = {
        BUN_INSTALL = bunInstallPath;
        NPM_CONFIG_TMP = "$XDG_RUNTIME_DIR/npm";
      };
    };
  };
}
