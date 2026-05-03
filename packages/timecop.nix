{
  pkgs,
  stdenv,
}: let
  packages = {
    aarch64-darwin = {
      suffix = "darwin-aarch64";
      hash = "sha256:e95b8de19f3c7bc31fe3316c526abe45de821d59eda1e3f3a0cdcf9308879664";
    };
    x86_64-linux = {
      suffix = "linux-x86_64";
      hash = "sha256:4e82aa44aa69441f72b1675e9df2b95c29b9585d358c09a6bfc691258d13ab08";
    };
  };
  source =
    packages.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  pkgs.stdenv.mkDerivation rec {
    pname = "timecop";
    version = "0.1.13";

    src = pkgs.fetchurl {
      url = "https://github.com/kamilmac/${pname}/releases/download/v${version}/${pname}-${source.suffix}.tar.gz";
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
      description = "A terminal UI for reviewing GitHub PRs and local branches — built for the agent loop.";
      homepage = "https://github.com/kamilmac/timecop";
      mainProgram = pname;
    };
  }
