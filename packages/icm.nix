{
  lib,
  pkgs,
  stdenv,
}: let
  packages = {
    aarch64-darwin = {
      suffix = "aarch64-apple-darwin";
      hash = "sha256-Mi3DlVIsR8PDrIlDZfX6NPDUcHIxzn/S9MoRrpi2+jM=";
    };
    x86_64-linux = {
      suffix = "x86_64-unknown-linux-gnu";
      hash = "sha256-4t5Pm2VvMPsMKTlMU1pLi2xz+GpbyFODwrZ4lcD7iO8=";
    };
  };
  source =
    packages.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  pkgs.stdenv.mkDerivation rec {
    pname = "icm";
    version = "0.10.47";

    src = pkgs.fetchurl {
      url = "https://github.com/rtk-ai/${pname}/releases/download/${pname}-v${version}/${pname}-${source.suffix}.tar.gz";
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
      description = "Permanent memory for AI agents. Single binary, zero dependencies, MCP native";
      homepage = "https://github.com/rtk-ai/icm";
      license = lib.licenses.asl20;
      mainProgram = pname;
    };
  }
