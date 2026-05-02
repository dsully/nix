{
  lib,
  pkgs,
  stdenv,
}: let
  packages = {
    aarch64-darwin = {
      suffix = "darwin-arm64";
      hash = "sha256:0bef7ceb9feab098a72c912ed1f04ff9d5aee0296c1155a757a3b324ab383688";
    };
    x86_64-linux = {
      suffix = "linux-amd64";
      hash = "sha256:40c50a81e46415fd3d0979bd29a46b6adc40401f2b738c507d035ac75c04f63b";
    };
  };
  source =
    packages.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  pkgs.stdenv.mkDerivation rec {
    pname = "rip-go";
    version = "0.2.3";

    src = pkgs.fetchurl {
      url = "https://github.com/roniel-rhack/rip-go/releases/download/v${version}/rip-go-${source.suffix}.tar.gz";
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
      description = "Fuzzy find and kill processes from your terminal with real-time updates";
      homepage = "https://github.com/roniel-rhack/rip-go";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
