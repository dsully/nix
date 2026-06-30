{
  config,
  pkgs,
  ...
}: let
  homeDir = config.home.homeDirectory;
in {
  home = {
    sessionVariables = {
      # Silence direnv logging. Hook is invoked via vendor_conf.d/
      DIRENV_LOG_FORMAT = "";
    };
  };

  programs = {
    direnv = {
      enable = true;

      package = pkgs.direnv.overrideAttrs (_: {
        doCheck = false;
      });

      config = {
        global = {
          hide_env_diff = true;
          load_dotenv = true;
          strict_env = true;
          warn_timeout = "10s";
        };
        whitelist = {
          prefix = [
            "${homeDir}/.config"
            "${homeDir}/dev/home"
            "${homeDir}/dev/work"
          ];
        };
      };

      nix-direnv = {
        enable = true;
      };
    };
  };
}
