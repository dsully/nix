{
  lib,
  pkgs,
  stdenv,
}: let
  packages = {
    aarch64-darwin = {
      suffix = "darwin-arm64";
      hash = "sha256-/Cb+WFEYIRZCm2gW/X+RKAuC4GVbQsmL2sSpG4M6/WA=";
    };
    x86_64-linux = {
      suffix = "linux-x64";
      hash = "sha256-OjeUYuCHsB9PT78GsWYUKr3ecGrHVTmMNcLsQcksbTY=";
    };
  };
  source =
    packages.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  pkgs.stdenv.mkDerivation rec {
    pname = "pi-bolt";
    version = "1.2.0";

    src = pkgs.fetchurl {
      url = "https://github.com/opensec-git/Pi-Bolt/releases/download/bolt-v${version}/${pname}-${source.suffix}.tar.xz";
      inherit (source) hash;
    };

    dontConfigure = true;
    dontBuild = true;

    # AOT image verifies its own appended sections; strip/patchelf/re-sign corrupt it.
    dontFixup = true;

    installPhase = ''
      runHook preInstall

      # The runtime reads package.json, theme/ and export-html/ beside the executable.
      mkdir -p $out/libexec $out/bin
      cp -R . $out/libexec/pi

      # PIBOLT_COMPILED_DIR: a `pi compile --out` build of this exact package, stamped by .nix-source.
      # PIBOLT_NPM stops self-update into ~/.pi-bolt; PI_PACKAGE_DIR is inherited from parent pi processes, so pin it.
      cat > $out/bin/pi <<'EOF'
      #!${pkgs.runtimeShell}

      d=@out@/libexec/pi
      c=''${PIBOLT_COMPILED_DIR:-}

      if [[ -n $c && -x $c/pi ]] && read -r s < "$c/.nix-source" 2>/dev/null && [[ $s == @out@ ]]; then d=$c; fi

      export PIBOLT_NPM=1 PI_PACKAGE_DIR=$d

      exec -a pi "$d/pi" "$@"
      EOF

      substituteInPlace $out/bin/pi --subst-var out
      chmod +x $out/bin/pi

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
