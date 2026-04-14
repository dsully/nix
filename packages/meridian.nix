{
  lib,
  stdenvNoCC,
  bun,
  claude-code,
  curl,
  fetchurl,
  opencode,
  python3,
  writeShellScript,
}:
stdenvNoCC.mkDerivation rec {
  pname = "meridian";
  version = "1.35.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/@rynfar/meridian/-/meridian-${version}.tgz";
    hash = "sha256-fbCklMGNlzbe2GD5hJOeRpRGVMueHXuFzBGerX6ohm8=";
  };

  sourceRoot = "package";

  installPhase = let
    meridianWrapper = writeShellScript "meridian" ''
      CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/meridian"
      PKG="@out@/libexec/meridian"

      # Install node_modules on first run or when the package changes.
      if [ ! -f "$CACHE_DIR/.stamp" ] || [ "$(cat "$CACHE_DIR/.stamp")" != "$PKG" ]; then
        rm -rf "$CACHE_DIR"
        mkdir -p "$CACHE_DIR"
        cp "$PKG/package.json" "$CACHE_DIR/"
        (cd "$CACHE_DIR" && ${lib.getExe bun} install --production 2>/dev/null)
        printf '%s' "$PKG" > "$CACHE_DIR/.stamp"
      fi

      export NODE_PATH="$CACHE_DIR/node_modules"
      exec ${lib.getExe bun} "$PKG/dist/cli.js" "$@"
    '';

    opencodeWrapper = writeShellScript "opencode-meridian" ''
      set -e

      export PATH="${lib.makeBinPath [claude-code]}:$PATH"
      PYTHON_GIL=1

      # Pick a random free port.
      PORT=$(${lib.getExe python3} -c \
        'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()')

      # Start meridian in the background.
      MERIDIAN_PORT=$PORT MERIDIAN_WORKDIR="$PWD" MERIDIAN_PASSTHROUGH="''${MERIDIAN_PASSTHROUGH:-1}" \
        "@out@/bin/meridian" > /dev/null 2>&1 &
      PROXY_PID=$!

      cleanup() { kill "$PROXY_PID" 2>/dev/null; wait "$PROXY_PID" 2>/dev/null; }
      trap cleanup EXIT INT TERM

      # Wait for the proxy to be ready (up to 10s).
      for _ in $(seq 1 100); do
        ${lib.getExe curl} -sf "http://127.0.0.1:$PORT/health" > /dev/null 2>&1 && break
        kill -0 "$PROXY_PID" 2>/dev/null || { echo "Proxy failed to start" >&2; exit 1; }
        sleep 0.1
      done

      ${lib.getExe curl} -sf "http://127.0.0.1:$PORT/health" > /dev/null 2>&1 \
        || { echo "Proxy didn't become healthy within 10 seconds" >&2; exit 1; }

      ANTHROPIC_API_KEY=x ANTHROPIC_BASE_URL="http://127.0.0.1:$PORT" \
        exec ${lib.getExe opencode} "$@"
    '';
  in ''
    runHook preInstall

    mkdir -p $out/libexec/meridian $out/bin
    cp -r dist plugin assets package.json README.md $out/libexec/meridian/

    substitute ${meridianWrapper} $out/bin/meridian --replace-fail "@out@" "$out"
    chmod +x $out/bin/meridian

    substitute ${opencodeWrapper} $out/libexec/meridian/opencode-wrapper --replace-fail "@out@" "$out"
    chmod +x $out/libexec/meridian/opencode-wrapper

    runHook postInstall
  '';

  meta = {
    description = "Proxy that bridges Anthropic's official SDK to enable Claude Max in third-party tools";
    homepage = "https://github.com/rynfar/meridian";
    license = lib.licenses.mit;
    mainProgram = pname;
    platforms = lib.platforms.all;
  };
}
