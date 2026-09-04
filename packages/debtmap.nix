{
  lib,
  pkgs,
  stdenv,
}: let
  packages = {
    aarch64-darwin = {
      suffix = "aarch64-apple-darwin";
      hash = "sha256-U5t8udyL3dp2BwzDC5wlBI6ZKfR4tMTTTE8TeZT3LqQ=";
    };
    x86_64-linux = {
      suffix = "x86_64-unknown-linux-gnu";
      hash = "sha256-6EWonhNL2w/uEHfM8HX9zqTDGe4RSWuoprYRIJvST40=";
    };
  };
  source =
    packages.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  pkgs.stdenv.mkDerivation rec {
    pname = "debtmap";
    version = "0.23.0";

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
