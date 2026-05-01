{
  lib,
  pkgs,
  stdenv,
}: let
  packages = {
    aarch64-darwin = {
      suffix = "aarch64-apple-darwin";
      hash = "sha256:b63691905f453e8b166ccecd3b2197d89faa3c35e3835f819deae20b37136358";
    };
    x86_64-linux = {
      suffix = "unknown-linux-gnu";
      hash = "sha256:87a1f15e46ff8bdacd62bfb81623d9dd70df333eebae3a0c9ee1ce5fef79657f";
    };
  };
  source =
    packages.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  pkgs.stdenv.mkDerivation rec {
    pname = "rust-mcp-filesystem";
    version = "0.4.1";

    src = pkgs.fetchurl {
      url = "https://github.com/rust-mcp-stack/${pname}/releases/download/v${version}/${pname}-${source.suffix}.tar.gz";
      inherit (source) hash;
    };

    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;
    sourceRoot = "${pname}-${source.suffix}";

    nativeBuildInputs = lib.optionals stdenv.isLinux [
      pkgs.autoPatchelfHook
    ];

    installPhase = ''
      runHook preInstall

      install -m755 -D ${pname} $out/bin/${pname}

      runHook postInstall
    '';

    meta = {
      description = "Blazing-fast, asynchronous MCP server for seamless filesystem operations";
      homepage = "https://github.com/rust-mcp-stack/rust-mcp-filesystem";
      changelog = "https://github.com/rust-mcp-stack/rust-mcp-filesystem/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
