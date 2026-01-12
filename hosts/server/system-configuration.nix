{
  flake,
  lib,
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
          Cmnd_Alias LIQUIDCTL = ${lib.getExe pkgs.liquidctl} (list|status)
          Cmnd_Alias NIX = ${lib.getExe pkgs.lix} *
          Cmnd_Alias VPN_CLEANUP = /sbin/ip link delete vpn_s, /sbin/ip netns delete vpn

          %admin ALL=(ALL:ALL) NOPASSWD:SETENV:LIQUIDCTL
          %admin ALL=(ALL:ALL) NOPASSWD:SETENV:NIX
          %admin ALL=(ALL:ALL) NOPASSWD:SETENV:SYSTEM_MANAGER
          %admin ALL=(ALL:ALL) NOPASSWD:VPN_CLEANUP

          Defaults:%sudo env_keep += "PATH SSH_AGENT_PID SSH_AUTH_SOCK TERM TERMINFO"
        '';
      };

      systemPackages = with pkgs; [
        fish
        liquidctl
        system-manager
        vopono
      ];
    };

    systemd.services.vopono-daemon = {
      enable = true;
      description = "Vopono root daemon";
      wants = ["network-online.target"];
      after = ["network-online.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${lib.getExe pkgs.vopono} daemon";
        ExecStopPost = "-/bin/sh -c '/sbin/ip link delete vpn_s 2>/dev/null; /sbin/ip netns delete vpn 2>/dev/null; true'";
        Restart = "on-failure";
        RestartSec = "2s";
        Environment = [
          "RUST_LOG=info"
          "PATH=/usr/sbin:/usr/bin:/sbin:/bin"
        ];
      };
      wantedBy = ["system-manager.target"];
    };
  };
}
