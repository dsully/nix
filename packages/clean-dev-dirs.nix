{
  lib,
  pkgs,
  stdenv,
}: let
  packages = {
    aarch64-darwin = {
      suffix = "macos-arm64";
      hash = "sha256-2FznQZoZOWeJFxj0buv2N7iKDqPIlgyAJ8pIDrOGPX8=";
    };
    x86_64-linux = {
      suffix = "linux-x86_64";
      hash = "sha256:a25e5591f63437d6487780ce53a53be741e9aa83a0956c9977e330a8541a668f";
    };
  };
  source =
    packages.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  pkgs.stdenv.mkDerivation rec {
    pname = "clean-dev-dirs";
    version = "2.8.2";

    src = pkgs.fetchurl {
      url = "https://github.com/${pname}/${pname}/releases/download/v${version}/${pname}-${version}-${source.suffix}.tar.gz";
      inherit (source) hash;
    };

    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;
    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      install -m755 -D ${pname} $out/bin/${pname}

      runHook postInstall
    '';

    meta = {
      description = "A fast and efficient CLI tool for recursively cleaning Rust target/ and Node.js node_modules/ directories to reclaim disk space";
      homepage = "https://github.com/TomPlanche/clean-dev-dirs";
      license = with lib.licenses; [asl20 mit];
      mainProgram = pname;
    };
  }
