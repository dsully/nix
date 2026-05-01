{
  lib,
  pkgs,
  stdenv,
}: let
  packages = {
    aarch64-darwin = {
      suffix = "aarch64-apple-darwin";
      hash = "sha256:a98b0786d43a563bfe33dc5666f19770e95ffd8708e5cbbccdf31f375d93fa59";
    };
    x86_64-linux = {
      suffix = "x86_64-unknown-linux-musl";
      hash = "sha256:b4d04cf2462ce3b43e05dc2f00bca225205946a6fa4653c63294253e30294511";
    };
  };
  source =
    packages.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  pkgs.stdenv.mkDerivation rec {
    pname = "leadr";
    version = "2.8.5";

    src = pkgs.fetchurl {
      url = "https://github.com/ll-nick/${pname}/releases/download/v${version}/${pname}-v${version}-${source.suffix}";
      inherit (source) hash;
    };

    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;
    dontUnpack = true;

    nativebuildInputs = lib.optionals stdenv.isLinux [
      pkgs.autoPatchelfHook
    ];

    installPhase = ''
      runHook preInstall

      install -m755 -D $src $out/bin/${pname}

      runHook postInstall
    '';

    meta = {
      description = "Shell aliases on steroids";
      homepage = "https://crates.io/crates/leadr";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
