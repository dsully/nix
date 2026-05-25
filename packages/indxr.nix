{
  lib,
  pkgs,
  stdenv,
}: let
  packages = {
    aarch64-darwin = {
      suffix = "aarch64-apple-darwin";
      hash = "sha256:c1a2df6cc6a9a436eae0d77ac39cea13fd9ac90bc219920afd73ca8b562aac08";
    };
    x86_64-linux = {
      suffix = "x86_64-unknown-linux-gnu";
      hash = "sha256:eaae7bc13e1c89ca506cf5aa2b6db9396089d931017c8938d1f4c771f51a5889";
    };
  };
  source =
    packages.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  pkgs.stdenv.mkDerivation rec {
    pname = "indxr";
    version = "0.4.0";

    src = pkgs.fetchurl {
      url = "https://github.com/bahdotsh/${pname}/releases/download/v${version}/${pname}-${source.suffix}.tar.gz";
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
      description = "A fast codebase indexer and knowledge wiki for AI agents";
      homepage = "https://github.com/bahdotsh/indxr";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
