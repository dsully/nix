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

  npmCacheDir = "${config.xdg.cacheHome}/npm";
in {
  options.packageTools.javascript = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    apply = lib.unique;
  };

  config = lib.mkIf (config.packageTools.javascript != [] && pkgs.stdenv.isDarwin) {
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
        NPM_CONFIG_CACHE = npmCacheDir;
        NPM_CONFIG_PREFIX = npmCacheDir;
        NPM_CONFIG_TMP = "$XDG_RUNTIME_DIR/npm";
        NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/config";
      };
    };
  };
}
