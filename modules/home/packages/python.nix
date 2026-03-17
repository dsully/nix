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
    config.packageTools.uvTools;
in {
  options.packageTools.uvTools = lib.mkOption {
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
    packageTools.uvTools = [
      # https://github.com/cocoindex-io/cocoindex-code
      {
        package = "cocoindex-code";
        prerelease = true;
        withPackages = ["cocoindex>=1.0.0a24"];
      }
      {package = "git+https://github.com/ast-grep/ast-grep-mcp";}
      {package = "mcp-nixos";}
      {package = "ptpython";}
      {package = "pyproject";}
      {package = "pyproject-fmt";}
      {package = "pytest-language-server";}
      {package = "xmlformatter";}
    ];

    home.activation.uvTools = lib.mkIf (config.packageTools.uvTools != []) (
      lib.hm.dag.entryAfter ["writeBoundary" "installPackages"] ''
        export PATH="${lib.makeBinPath [pkgs.git]}:$PATH"
        ${installScript}
      ''
    );
  };
}
