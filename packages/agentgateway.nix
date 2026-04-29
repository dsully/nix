{
  lib,
  pkgs,
  stdenv,
}: let
  srcs = {
    aarch64-darwin = {
      suffix = "darwin-arm64";
      hash = "sha256:e6637efb0e299dbc9af81c8b3a7867424afa4327a9b758d4fea3dbe4e42607df";
    };
    x86_64-linux = {
      suffix = "linux-amd64";
      hash = "sha256:955efb97afdcc7e106cee16d3f279c54ffe7e37dc8e9261d2594206711fb4701";
    };
  };
  sysSrc =
    srcs.${pkgs.stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");
in
  pkgs.stdenv.mkDerivation rec {
    pname = "agentgateway";
    version = "1.1.0";

    src = pkgs.fetchurl {
      url = "https://github.com/agentgateway/agentgateway/releases/download/v${version}/agentgateway-${sysSrc.suffix}";
      inherit (sysSrc) hash;
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

      install -m755 -D $src $out/bin/agentgateway

      runHook postInstall
    '';

    meta = {
      description = "Next Generation Agentic Proxy";
      homepage = "https://github.com/agentgateway/agentgateway";
      license = pkgs.lib.licenses.asl20;
      mainProgram = "agentgateway";
    };
  }
