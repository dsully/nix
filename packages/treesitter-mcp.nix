{
  lib,
  pkgs,
  stdenv,
}: let
  packages = {
    aarch64-darwin = {
      suffix = "aarch64-apple-darwin";
      hash = "sha256:03a710dbabee6ef9c109d407051b609d6e99036ba79ea0af5fefbe56b8eb7075";
    };
    x86_64-linux = {
      suffix = "unknown-linux-gnu";
      hash = "sha256:5c960aeb0fd26667daea298a980f4c5b2a3e29d45c05cfa2d61c2ce07332caec";
    };
  };
  source =
    packages.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  pkgs.stdenv.mkDerivation rec {
    pname = "treesitter-mcp";
    version = "0.7.0";

    src = pkgs.fetchurl {
      url = "https://github.com/Christoph/${pname}/releases/download/v${version}/${pname}-${source.suffix}.tar.gz";
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
      description = "Tree-sitter MCP Server exposes powerful code analysis tools through the MCP protocol";
      homepage = "https://github.com/Christoph/treesitter-mcp";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
