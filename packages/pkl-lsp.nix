{pkgs, ...}:
with pkgs;
  stdenv.mkDerivation rec {
    pname = "pkl-lsp";
    version = "0.2.0";

    meta = {
      description = "Language server for Pkl, implementing the server-side of the Language Server Protocol";
      homepage = "https://github.com/apple/pkl-lsp";
      license = lib.licenses.asl20;
      platforms = lib.platforms.all;
    };

    src = fetchurl {
      url = "https://github.com/apple/pkl-lsp/releases/download/${version}/${pname}-${version}.jar";
      sha256 = "sha256-X0vjugzNSF3LUJAku/sUkNWrjcZCNUwwuTv6q3Dmsek=";
    };

    nativeBuildInputs = [makeWrapper];
    buildInputs = [jdk23_headless];

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/share/java $out/bin
      cp $src $out/share/java/${pname}-${version}.jar

      # shellcheck disable=SC1072,SC1073,SC1009
      makeWrapper ${jdk23_headless}/bin/java $out/bin/${pname} --add-flags "-jar $out/share/java/${pname}-${version}.jar"'';
  }
