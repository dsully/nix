{
  lib,
  mkSystemModule,
  pkgs,
  ...
}: let
  logFile = "/var/log/nix-exec.log";

  # TCC checks the launchd job's own executable, so eslogger must be ProgramArguments[0]
  # (a wrapper script that execs it stays responsible); it writes to the unified log
  # and this unprivileged-for-TCC filter reads it back.
  filter = pkgs.writeShellScript "exec-log-filter" ''
    /usr/bin/log stream --level info --style ndjson \
        --predicate 'subsystem == "com.apple.eslogger" AND category == "events"' \
      | ${lib.getExe pkgs.jq} --unbuffered -rR '
          fromjson? | .eventMessage? | fromjson? | (.event.exec.target.executable.path)? // empty
          | select(startswith("/nix/store/"))
          | "\(now | strflocaltime("%Y-%m-%d")) \(.)"' \
      | /usr/bin/awk '!seen[$0]++ { print; fflush() }' >> ${logFile}
  '';

  nix-unused = pkgs.writeShellApplication {
    name = "nix-unused";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      days=''${1:-90}
      log=${logFile}

      if [[ ! -s $log ]]; then
        echo "$log is missing or empty. Check: sudo launchctl print system/org.nixos.exec-log, and Full Disk Access for /usr/bin/eslogger" >&2
        exit 1
      fi

      cutoff=$(date -d "-$days days" +%F)
      echo "Logged since $(head -n1 "$log" | cut -d' ' -f1). Packages not run since $cutoff:"

      realpath -q "$HOME"/.local/state/nix/profile/bin/* "$HOME"/.nix-profile/bin/* /run/current-system/sw/bin/* \
        | awk -v cutoff="$cutoff" '
            FNR == NR { split($2, p, "/"); last[p[4]] = $1; next }
            { split($0, p, "/"); if (p[2] == "nix") pkg[p[4]] = 1 }
            END {
              for (k in pkg)
                if (!(k in last) || last[k] < cutoff)
                  printf "%-10s %s\n", (k in last ? last[k] : "never"), substr(k, 34)
            }' "$log" - \
        | sort
    '';
  };
in
  mkSystemModule {
    name = "exec-log";

    config = {
      environment.systemPackages = [nix-unused];

      # Stream-only: keeps every exec event out of the persistent unified log store.
      system.activationScripts.postActivation.text = lib.mkAfter ''
        /usr/bin/log config --subsystem com.apple.eslogger --mode "persist:off" || true
      '';

      launchd.daemons = {
        # Needs a one-time manual grant: System Settings > Privacy & Security >
        # Full Disk Access > + > Cmd-Shift-G /usr/bin/eslogger.
        exec-log.serviceConfig = {
          ProgramArguments = ["/usr/bin/eslogger" "--oslog" "exec"];
          RunAtLoad = true;
          KeepAlive = true;
          ThrottleInterval = 300;
          StandardErrorPath = "/var/log/nix-exec.err.log";
        };

        exec-log-filter.serviceConfig = {
          ProgramArguments = ["${filter}"];
          RunAtLoad = true;
          KeepAlive = true;
          ThrottleInterval = 60;
          StandardErrorPath = "/var/log/nix-exec.err.log";
        };
      };
    };
  }
