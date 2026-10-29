{
  lib,
  pkgs,
  stdenv,
}: let
  packages = {
    aarch64-darwin = {
      suffix = "darwin_arm64";
      hash = "sha256-xTBCziaGIimb2yw2w1S7kMr/Cw8ZgndNE+2OCPXjscE=";
    };
    x86_64-linux = {
      suffix = "linux_amd64";
      hash = "sha256-3BNyVNgfodymo9tCOfLTwEXbvKZrCweHC05RLSVqK8c=";
    };
  };
  source =
    packages.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  pkgs.stdenv.mkDerivation rec {
    pname = "gortex";
    version = "0.64.11";

    src = pkgs.fetchurl {
      url = "https://github.com/zzet/gortex/releases/download/v${version}/gortex_${source.suffix}.tar.gz";
      inherit (source) hash;
    };

    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;
    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      install -m755 -D gortex $out/bin/gortex

      runHook postInstall
    '';

    meta = {
      description = "High-performance code-intelligence engine for AI agents and IDE";
      homepage = "https://github.com/zzet/gortex";
      license = lib.licenses.asl20;
      mainProgram = pname;
    };
  }
