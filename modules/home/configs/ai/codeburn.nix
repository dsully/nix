{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  packageTools.javascript = ["codeburn"];

  launchd.agents.codeburn-menubar = {
    enable = true;
    config = {
      ProgramArguments = [
        "${config.home.homeDirectory}/Applications/CodeBurnMenubar.app/Contents/MacOS/CodeBurnMenubar"
      ];

      EnvironmentVariables = {
        CODEBURN_BIN = "${config.home.homeDirectory}/.local/state/nix/profile/bin/node ${config.home.homeDirectory}/.bun/bin/codeburn";
        PATH = "${config.home.homeDirectory}/.local/state/nix/profile/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
      KeepAlive = true;
      RunAtLoad = true;
      ProcessType = "Interactive";
    };
  };
}
