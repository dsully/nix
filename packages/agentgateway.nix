{
  pkgs,
  stdenv,
}: let
  packages = {
    aarch64-darwin = {
      suffix = "darwin-arm64";
      hash = "sha256-VLwdQnMt8230DiddiJmNgNmNjdhgEzO5PqAuw2zx5R8=";
    };
    x86_64-linux = {
      suffix = "linux-amd64";
      hash = "sha256:9e04efb06b1b412abd6e8250ce4120173288568e357e663662f2b8d325bd0e24";
    };
  };
  source =
    packages.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  pkgs.stdenv.mkDerivation rec {
    pname = "agentgateway";
    version = "1.2.0-alpha.1";

    src = pkgs.fetchurl {
      url = "https://github.com/${pname}/${pname}/releases/download/v${version}/${pname}-${source.suffix}";
      inherit (source) hash;
    };

    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;
    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      install -m755 -D $src $out/bin/${pname}

      runHook postInstall
    '';

    meta = {
      description = "Next Generation Agentic Proxy";
      homepage = "https://github.com/agentgateway/agentgateway";
      license = pkgs.lib.licenses.asl20;
      mainProgram = pname;
    };
  }
