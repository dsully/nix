{
  config,
  lib,
  my,
  ...
}: let
  muxExe = lib.getExe my.pkgs.mcp-mux;

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
  configHash = builtins.hashString "sha256" (muxExe + builtins.toJSON config.programs.mcp.servers);

  stateFile = "${config.xdg.stateHome}/mcp-mux/config-hash";
in {
  config = lib.mkIf config.programs.mcp.enable {
    home.activation.restartMcpMux =
      lib.hm.dag.entryAfter ["writeBoundary"]
      # bash
      ''
        state="${stateFile}"

        if [ "$(cat "$state" 2>/dev/null)" != "${configHash}" ]; then
          run ${muxExe} stop --force || true
          run mkdir -p "$(dirname "$state")"
          run sh -c 'printf "%s\n" "$1" > "$2"' _ "${configHash}" "$state"
        fi
      '';
  };
}
