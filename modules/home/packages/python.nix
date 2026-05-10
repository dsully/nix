{
  config,
  lib,
  pkgs,
  ...
}: let
  installScript =
    lib.concatMapStringsSep "\n" (
      tool: let
        spec =
          if tool.extras != ""
          then "${tool.package}[${tool.extras}]"
          else tool.package;

        prereleaseFlag = lib.optionalString tool.prerelease "--prerelease=explicit";

        withFlags = lib.concatMapStringsSep " " (dep: "--with '${dep}'") tool.withPackages;

        installCmd = ''
          ${lib.getExe pkgs.uv} tool install "${spec}" --quiet --upgrade ${prereleaseFlag} ${withFlags}
        '';

        injectCmds =
          lib.concatMapStringsSep "\n" (dep: ''
            ${lib.getExe pkgs.uv} tool inject "${tool.package}" "${dep}" --quiet 2>/dev/null || true
          '')
          tool.inject;
      in
        installCmd + injectCmds
    )
    config.packageTools.python;
in {
  options.packageTools.python = lib.mkOption {
    type = lib.types.listOf (
      lib.types.submodule {
        options = {
          package = lib.mkOption {
            type = lib.types.str;
          };

          extras = lib.mkOption {
            type = lib.types.str;
            default = "";
          };

          prerelease = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };

          withPackages = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
          };

          inject = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
          };
        };
      }
    );
    default = [];
  };

  config = {
    home.activation.python = lib.mkIf (config.packageTools.python != []) (
      lib.hm.dag.entryAfter ["writeBoundary" "installPackages"] ''
        export PATH="${lib.makeBinPath [pkgs.git]}:$PATH"
        ${installScript}
      ''
    );

    xdg.configFile."ptpython/config.py".text = builtins.readFile ../../../dotfiles/ptpython/config.py;
  };
}
