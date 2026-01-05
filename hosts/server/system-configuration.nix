{
  flake,
  pkgs,
  system-manager,
  ...
}: {
  imports = [
    flake.modules.system-manager.common
    ./options.nix
  ];

  config = {
    environment = {
      etc = {
        "sudoers.d/10-nix-commands".text = ''
          Cmnd_Alias SYSTEM_MANAGER = ${system-manager}/bin/system-manager (build|switch) *
          Cmnd_Alias LIQUIDCTL = ${pkgs.liquidctl}/bin/liquidctl (list|status)
          Cmnd_Alias NIX = ${pkgs.lix}/bin/nix *

          %admin ALL=(ALL:ALL) NOPASSWD:SETENV:LIQUIDCTL
          %admin ALL=(ALL:ALL) NOPASSWD:SETENV:NIX
          %admin ALL=(ALL:ALL) NOPASSWD:SETENV:SYSTEM_MANAGER

          Defaults:%sudo env_keep += "PATH SSH_AGENT_PID SSH_AUTH_SOCK TERM TERMINFO"
        '';
      };

      systemPackages = with pkgs; [
        fish
        liquidctl
        system-manager
      ];
    };
  };
}
