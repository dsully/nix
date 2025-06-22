{
  pkgs,
  system-manager,
  ...
}: {
  config = {
    environment = {
      etc = {
        "sudoers.d/10-nix-commands".text = let
          commands = [
            "/nix/store/*/activate"
            "/nix/var/nix/profiles/default/bin/nix*"
            "/run/system-manager/sw/bin/liquidctl"
            "/run/system-manager/sw/bin/system-manager"
          ];
          commandsString = builtins.concatStringsSep ", " commands;
        in ''
          %admin ALL=(ALL:ALL) NOPASSWD:SETENV ${commandsString}

          Defaults:%sudo env_keep += "PATH SSH_AGENT_PID SSH_AUTH_SOCK TERM TERMINFO"
        '';
      };

      systemPackages = with pkgs; [
        liquidctl
        system-manager
      ];
    };

    nixpkgs.hostPlatform = "x86_64-linux";
  };
}
