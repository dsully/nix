{
  flake,
  pkgs,
  lib,
  ...
}: let
  local =
    (flake.inputs.upstream or flake).packages.${pkgs.system} or {};
in {
  config = lib.mkMerge [
    (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      systemd.user.services.lolcate = {
        Unit.Description = "Update lolcate database";

        Service = {
          Type = "oneshot";
          ExecStart = "${lib.getExe local.lolcate-rs} --all --update";
          Nice = 19;
          IOSchedulingClass = "idle";
          IOSchedulingPriority = 7;
        };
      };

      systemd.user.timers.lolcate = {
        Unit.Description = "Update lolcate database every 6 hours";

        Timer = {
          OnCalendar = "0/6:00:00"; # Every 6 hours starting at midnight
          Persistent = true;
        };

        Install.WantedBy = ["timers.target"];
      };
    })

    (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      launchd.agents.lolcate = {
        enable = true;
        config = {
          Label = "localhost.lolcate";

          ProgramArguments = [
            "${lib.getExe local.lolcate-rs}"
            "--all"
            "--update"
          ];

          RunAtLoad = true;

          StartCalendarInterval = [
            {Hour = 0;}
            {Hour = 6;}
            {Hour = 12;}
            {Hour = 18;}
          ];

          ProcessType = "Background";
          LowPriorityIO = true;
        };
      };
    })
  ];
}
