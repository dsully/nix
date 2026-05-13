{
  lib,
  pkgs,
  stdenv,
}: let
  packages = {
    aarch64-darwin = {
      suffix = "aarch64-apple-darwin";
      hash = "sha256:ba690bebfc793184d75080c96d7784cb3a808b83e5098c5f36156aeff8ae7e12";
    };
    x86_64-linux = {
      suffix = "x86_64-unknown-linux-gnu";
      hash = "sha256:4c90cac9ddd8490678f78e7469eef1ca06f4de3edeb094c3b48f22f339d08b23";
    };
  };
  source =
    packages.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  pkgs.stdenv.mkDerivation rec {
    pname = "just-mcp";
    version = "0.2.0";

    src = pkgs.fetchurl {
      url = "https://github.com/toolprint/${pname}/releases/download/v${version}/${pname}-v${version}-${source.suffix}.tar.gz";
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
      description = "Share the same project justfile tasks with your AI Coding Agent";
      homepage = "https://github.com/toolprint/just-mcp";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
