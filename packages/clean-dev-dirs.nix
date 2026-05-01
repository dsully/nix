{
  lib,
  pkgs,
  stdenv,
}: let
  packages = {
    aarch64-darwin = {
      suffix = "macos-arm64";
      hash = "sha256:ca8aeaf367f70232798fc41822b61810584b85d973f0cc1bb88294688c3d4f9e";
    };
    x86_64-linux = {
      suffix = "linux-x86_64";
      hash = "sha256:65ea6515c832e6eb88c046f2ec46fa76824921e052cab0375d59c51439eb0ffc";
    };
  };
  source =
    packages.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  pkgs.stdenv.mkDerivation rec {
    pname = "clean-dev-dirs";
    version = "2.8.0";

    src = pkgs.fetchurl {
      url = "https://github.com/${pname}/${pname}/releases/download/v${version}/${pname}-${version}-${source.suffix}.tar.gz";
      inherit (source) hash;
    };

    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;
    sourceRoot = ".";

    nativeBuildInputs = lib.optionals stdenv.isLinux [
      pkgs.autoPatchelfHook
    ];

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
