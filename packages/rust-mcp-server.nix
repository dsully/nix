{
  lib,
  pkgs,
  stdenv,
}: let
  packages = {
    aarch64-darwin = {
      suffix = "aarch64-apple-darwin";
      hash = "sha256-uoFBOwfkm3F7A+U66D9PdnsZaBpmqEl85gBPnSpVXHA=";
    };
    x86_64-linux = {
      suffix = "x86_64-unknown-linux-gnu";
      hash = "sha256-9bLCA7MsT4tMsejIsXssGQCdR+SmkL36ra4alag0AAQ=";
    };
  };
  source =
    packages.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  pkgs.stdenv.mkDerivation rec {
    pname = "rust-mcp-server";
    version = "0.4.0";

    src = pkgs.fetchurl {
      url = "https://github.com/Vaiz/${pname}/releases/download/v${version}/${pname}-${source.suffix}.tar.gz";
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
      description = "MCP server for development in Rust";
      homepage = "https://github.com/Vaiz/rust-mcp-server";
      changelog = "https://github.com/Vaiz/rust-mcp-server/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.unlicense;
      mainProgram = pname;
    };
  }
