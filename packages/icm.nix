{
  lib,
  pkgs,
  stdenv,
}: let
  pname = "icm";
  version = "0.10.52";

  packages = {
    aarch64-darwin = {
      suffix = "aarch64-apple-darwin";
      hash = "sha256-HrBr8l7AAtIlEqx93R/s7xS4/4+jpHG7Mb4JVm6eS2Q=";
    };
    x86_64-linux = {
      suffix = "x86_64-unknown-linux-gnu";
      hash = "sha256-mdI0ufjzxlLYwE2QHiL/uxyI3+hfoW+AMhHqMMkXBN4=";
    };
  };
  source =
    packages.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  plugin = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/rtk-ai/${pname}/${pname}-v${version}/plugins/opencode-icm.ts";
    hash = "sha256-98chPzOOhHBWHD6T0Rn1Rs/b9jMYFtFsCW6/iFwax0w=";
  };
in
  pkgs.stdenv.mkDerivation {
    inherit pname version;

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
      install -m644 -D ${plugin} $out/plugins/opencode-icm.ts

      runHook postInstall
    '';

    meta = {
      description = "Permanent memory for AI agents. Single binary, zero dependencies, MCP native";
      homepage = "https://github.com/rtk-ai/icm";
      license = lib.licenses.asl20;
      mainProgram = pname;
    };
  }
