{pkgs, ...}:
with pkgs;
  stdenv.mkDerivation rec {
    pname = "pkl-lsp";
    version = "0.3.2";

    src = fetchurl {
      url = "https://github.com/apple/pkl-lsp/releases/download/${version}/${pname}-${version}.jar";
      hash = "sha256-83Tl4uhymlgkPX+npEmUM3tyKL8OAVVP4/MGq34goW8=";
    };

    nativeBuildInputs = [makeWrapper];
    buildInputs = [jdk24_headless];

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/share/java $out/bin
      cp $src $out/share/java/${pname}-${version}.jar

      # shellcheck disable=SC1072,SC1073,SC1009
      makeWrapper ${jdk24_headless}/bin/java $out/bin/${pname} --add-flags "-jar $out/share/java/${pname}-${version}.jar"'';

    meta = {
      description = "Language server for Pkl, implementing the server-side of the Language Server Protocol";
      homepage = "https://github.com/apple/pkl-lsp";
      license = lib.licenses.asl20;
      platforms = lib.platforms.all;
    };
  }
