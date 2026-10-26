{
  mkUserModule,
  config,
  inputs,
  pkgs,
  ...
}: let
  tokenPath = ".cache/tokens/rex.txt";
  netrcPath = ".cache/tokens/rex.netrc";

  homeDir = config.home.homeDirectory;

  systemHomeDir =
    if pkgs.stdenv.hostPlatform.isDarwin
    then "/Users/${config.system.userName}"
    else "/home/${config.system.userName}";
in
  mkUserModule {
    name = "rex";
    default = false;

    # Nix fetches the pre-release rex flake input with HTTP basic auth from this netrc.
    system.system.nixSettings.netrc-file = "${systemHomeDir}/${netrcPath}";

    home = {
      home.activation.rexNetrc = inputs.home-manager.lib.hm.dag.entryAfter ["writeBoundary" "onepassword-secrets"] ''
        if [ -f "${homeDir}/${tokenPath}" ]; then
          (umask 077; printf 'machine pkgs.superlogical.com login rex password %s\n' "$(cat "${homeDir}/${tokenPath}")" > "${homeDir}/${netrcPath}")
        fi
      '';

      programs.onepassword-secrets.secrets.rexPackageToken = {
        reference = "op://Services/Rex/credential";
        path = tokenPath;
      };
    };
  }
