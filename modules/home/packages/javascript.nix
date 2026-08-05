{
  config,
  lib,
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

  config = lib.mkMerge [
    # npm and bun base config apply unconditionally, independent of whether any
    # global tools are installed. Consumers layer registry overrides on top via
    # programs.npm.settings.
    {
      programs.npm = {
        enable = true;
        settings = {
          audit = false;
          cache = npmCacheDir;
          fund = false;
          prefix = npmCacheDir;
        };
      };

      programs.bun.enable = true;

      home.sessionVariables = {
        BUN_INSTALL = bunInstallPath;
        NPM_CONFIG_TMP = "$XDG_RUNTIME_DIR/npm";
      };
    }

    # Global tool installation only makes sense once tools are listed.
    (lib.mkIf (config.packageTools.javascript != []) {
      home = {
        activation.npmTools = lib.hm.dag.entryAfter ["writeBoundary" "installPackages"] ''
          ${installScript}
        '';

        sessionPath = [
          "${bunInstallPath}/bin"
          "${npmCacheDir}/bin"
        ];
      };
    })
  ];
}
