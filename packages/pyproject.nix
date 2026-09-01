{
  lib,
  pkgs,
  stdenv,
}: let
  packages = {
    aarch64-darwin = {
      suffix = "aarch64-apple-darwin";
      hash = "sha256-iuOs1rRRen6ohU/Um/1S5i2o2IODLGVrRLy4KG92Oxg=";
    };
    x86_64-linux = {
      suffix = "x86_64-unknown-linux-gnu";
      hash = "sha256-DMXWH9NHDYG8Se5ltRf4umYVPmgfQ4DvfDVnDalOmEE=";
    };
  };
  source =
    packages.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  pkgs.stdenv.mkDerivation rec {
    pname = "pyproject";
    version = "0.2.1";

    src = pkgs.fetchurl {
      url = "https://github.com/terror/pyproject/releases/download/${version}/pyproject-${version}-${source.suffix}.tar.gz";
      inherit (source) hash;
    };

    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;
    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      install -m755 -D pyproject $out/bin/pyproject

      runHook postInstall
    '';

    meta = {
      description = "TODO: add description";
      homepage = "https://github.com/terror/pyproject";
      license = lib.licenses.unfree;
      mainProgram = "pyproject";
    };
  }
