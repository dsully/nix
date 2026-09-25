{
  lib,
  pkgs,
  stdenv,
}: let
  packages = {
    aarch64-darwin = {
      suffix = "aarch64-apple-darwin";
      hash = "sha256-w/Di+zHB5KvxG3w7keuBE1i/3jhGjeX2qv2G9xcWTNU=";
    };
    x86_64-linux = {
      suffix = "x86_64-unknown-linux-gnu";
      hash = "sha256-m7H33AXtEZMn9ilX0mspG0UBmQ8ixTPfJiuGqCkkR1Y=";
    };
  };
  source =
    packages.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  pkgs.stdenv.mkDerivation rec {
    pname = "debtmap";
    version = "0.24.1";

    src = pkgs.fetchurl {
      url = "https://github.com/iepathos/debtmap/releases/download/${version}/debtmap-${source.suffix}.tar.gz";
      inherit (source) hash;
    };

    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;
    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      install -m755 -D debtmap $out/bin/debtmap

      runHook postInstall
    '';

    meta = {
      description = "TODO: add description";
      homepage = "https://github.com/iepathos/debtmap";
      license = lib.licenses.unfree;
      mainProgram = pname;
    };
  }
