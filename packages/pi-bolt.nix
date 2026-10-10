{
  lib,
  pkgs,
  stdenv,
}: let
  packages = {
    aarch64-darwin = {
      suffix = "darwin-arm64";
      hash = "sha256:8986ab3997297d4de5f5dff62868264cd9d0a257e273fc382d2b566e49a8f0ca";
    };
    x86_64-linux = {
      suffix = "linux-x64";
      hash = "sha256:6a77f26798330f0920d44792fade5b5bbb8801264fc52766a23fb8dd28674754";
    };
  };
  source =
    packages.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  pkgs.stdenv.mkDerivation rec {
    pname = "pi-bolt";
    version = "0.8.0";

    src = pkgs.fetchurl {
      url = "https://github.com/opensec-git/Pi-Bolt/releases/download/bolt-v${version}/${pname}-${source.suffix}.tar.xz";
      inherit (source) hash;
    };

    nativeBuildInputs = [pkgs.makeWrapper];

    dontConfigure = true;
    dontBuild = true;
    # AOT image verifies its own appended sections; strip/patchelf/re-sign corrupt it.
    dontFixup = true;

    installPhase = ''
      runHook preInstall

      # The runtime reads package.json, theme/ and export-html/ beside the executable.
      mkdir -p $out/libexec
      cp -R . $out/libexec/pi

      # PIBOLT_NPM stops self-update into ~/.pi-bolt; PI_PACKAGE_DIR is inherited from parent pi processes, so pin it.
      makeWrapper $out/libexec/pi/pi $out/bin/pi \
        --argv0 pi \
        --set PIBOLT_NPM 1 \
        --set PI_PACKAGE_DIR $out/libexec/pi

      runHook postInstall
    '';

    meta = {
      description = "Pi coding agent compiled ahead of time to native code";
      homepage = "https://github.com/opensec-git/Pi-Bolt";
      license = lib.licenses.mit;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      platforms = builtins.attrNames packages;
      mainProgram = "pi";
    };
  }
