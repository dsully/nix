{
  lib,
  pkgs,
  stdenv,
}: let
  packages = {
    aarch64-darwin = {
      suffix = "Darwin_arm64";
      hash = "sha256:18bb0c9ab20e5815b9752ee88c7dbcb939f3db16645d46662a69b3d9531d03f2";
    };
    x86_64-linux = {
      suffix = "Linux_x86_64";
      hash = "sha256:6c9f64448c5e05ab4ab6a8be0233c918cc999c18776e047e7a9baa6b473111f6";
    };
  };
  source =
    packages.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  pkgs.stdenv.mkDerivation rec {
    pname = "version-lsp";
    version = "0.5.1";

    src = pkgs.fetchurl {
      url = "https://github.com/skanehira/${pname}/releases/download/v${version}/${pname}_${source.suffix}.tar.gz";
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
      description = "A Language Server Protocol (LSP) implementation that provides version checking diagnostics for package dependency files";
      homepage = "https://github.com/skanehira/version-lsp";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
