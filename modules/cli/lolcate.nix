{
  config,
  mkUserModule,
  pkgs,
  lib,
  my,
  ...
}: let
  # TCC keys grants to the code signature; signing a stable copy keeps them across rebuilds.
  signedLolcate = "${config.home.homeDirectory}/.local/libexec/lolcate";
in
  mkUserModule {
    name = "lolcate";

    home = lib.mkMerge [
      {
        home.packages = [
          my.pkgs.lolcate-rs
        ];
      }

      (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        systemd.user.services.lolcate = {
          Unit.Description = "Update lolcate database";

          Service = {
            Type = "oneshot";
            ExecStart = "${lib.getExe my.pkgs.lolcate-rs} --all --update";
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
        home.activation.lolcateSign =
          lib.hm.dag.entryAfter ["writeBoundary"]
          # bash
          ''
            src=${lib.getExe my.pkgs.lolcate-rs}
            dst=${lib.escapeShellArg signedLolcate}
            want="$src ''${XCODE_SIGN_IDENTITY:-}"

            if [[ ! -x "$dst" || "$(cat "$dst.stamp" 2>/dev/null)" != "$want" ]]; then
              run mkdir -p "$(dirname "$dst")"
              run install -m 755 "$src" "$dst"

              if [[ -z "''${XCODE_SIGN_IDENTITY:-}" ]]; then
                warnEcho "XCODE_SIGN_IDENTITY unset: $dst stays ad-hoc signed; Full Disk Access will reset on rebuild"
              elif run /usr/bin/codesign --force --sign "$XCODE_SIGN_IDENTITY" --identifier org.sully.lolcate "$dst"; then
                [[ -v DRY_RUN ]] || printf '%s' "$want" > "$dst.stamp"
              else
                warnEcho "codesign failed for $dst (keychain locked?)"
              fi
            fi
          '';

        launchd.agents.lolcate = {
          enable = true;
          waitForNixStore = false;
          config = {
            Label = "localhost.lolcate";

            ProgramArguments = [
              signedLolcate
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
          domain = lib.mkDefault "gui";
        };
      })
    ];
  }
