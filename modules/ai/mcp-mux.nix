{
  mkUserModule,
  ai,
  config,
  lib,
  my,
  pkgs,
  ...
}: let
  muxExe = lib.getExe my.pkgs.mcp-mux;
  psExe = "${pkgs.ps}/bin/ps";
  awkExe = lib.getExe pkgs.gawk;

  # mcp-mux runs a long-lived daemon that owns one upstream process per server
  # command line. It auto-starts on the first shim connection and only auto-exits
  # after several idle minutes, so it outlives a home-manager switch: after a
  # rebuild it keeps serving the previous generation's definitions (old upstream
  # store paths, changed args, or a stale mux binary) and new shims just connect
  # to that stale daemon. Nothing tears it down during active use.
  #
  # Stop it whenever the effective MCP config or the mux binary changes. The next
  # client session auto-starts a fresh daemon from the new definitions, and
  # resilient shims reconnect transparently. Gating on a config hash keeps
  # unrelated home switches from churning the shared daemon (and every live agent
  # session attached to it). muxExe is folded in explicitly so a mux version bump
  # triggers a restart even when the server set is unchanged.
  #
  # Live shims from the previous generation reconnect immediately and would
  # respawn the daemon from their own (old) binary; ai.muxEngineFile points them
  # at the current muxExe instead, so it must be written before the stop.
  configHash = builtins.hashString "sha256" (muxExe + builtins.toJSON config.programs.mcp.servers);

  stateDir = "${config.xdg.stateHome}/mcp-mux";
  stateFile = "${stateDir}/config-hash";
in
  mkUserModule {
    name = "mcp-mux";
    needs = ["ai"];
    default = false;

    home = lib.mkIf config.programs.mcp.enable {
      home.activation.restartMcpMux =
        lib.hm.dag.entryAfter ["writeBoundary"]
        # bash
        ''
          state="${stateFile}"
          engine="${ai.muxEngineFile}"

          run mkdir -p "${stateDir}" "$(dirname "$engine")"
          run sh -c 'printf "%s\n" "$1" > "$2.tmp" && mv "$2.tmp" "$2"' _ "${muxExe}" "$engine"

          mux_daemon_pids() {
            ${psExe} -U "$(id -u)" -o pid= -o args= \
              | ${awkExe} '$2 ~ /\/bin\/mcp-mux$/ && $3 == "daemon" && NF == 3 {print $1}'
          }

          if [ "$(cat "$state" 2>/dev/null)" != "${configHash}" ]; then
            run ${muxExe} stop --force || true

            # stop --force can block forever on an owner whose upstream already exited.
            for _ in {1..50}; do
              [ -z "$(mux_daemon_pids)" ] && break
              sleep 0.1
            done

            pids="$(mux_daemon_pids)"

            if [ -n "$pids" ]; then
              warnEcho "mcp-mux daemon did not exit after stop --force; sending SIGKILL to $pids"
              run kill -9 $pids || true
            fi

            run sh -c 'printf "%s\n" "$1" > "$2"' _ "${configHash}" "$state"
          fi
        '';
    };
  }
