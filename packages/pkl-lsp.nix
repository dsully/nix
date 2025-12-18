{pkgs, ...}:
with pkgs;
  stdenv.mkDerivation rec {
    pname = "pkl-lsp";
    version = "0.5.3";

    src = fetchurl {
      url = "https://github.com/apple/pkl-lsp/releases/download/${version}/${pname}-${version}.jar";
      hash = "sha256-oswF10l3ql60GHV7OiHOjhV/7c9ZxZmJ4Xt/3dLlgUs=";
    };

    nativeBuildInputs = [makeWrapper];
    buildInputs = [jdk25_headless];

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/share/java $out/bin
      cp $src $out/share/java/${pname}-${version}.jar

      # shellcheck disable=SC1072,SC1073,SC1009
      makeWrapper ${jdk25_headless}/bin/java $out/bin/${pname} --add-flags "-jar $out/share/java/${pname}-${version}.jar"'';

    meta = {
      description = "Language server for Pkl, implementing the server-side of the Language Server Protocol";
      homepage = "https://github.com/apple/pkl-lsp";
      license = lib.licenses.asl20;
      platforms = lib.platforms.all;
    };
  }
