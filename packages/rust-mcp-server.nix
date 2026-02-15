{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "rust-mcp-server";
    version = "0.3.4";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-uD9v4VhQ7i3EB6Wdwj2+mOri7fuGDMN+aMc2rS3Llf8=";
    };

    cargoHash = "sha256-2c7icCuy21874wKWUf1JHyom94Vmnr+U2pDm03GuJjY=";
    doCheck = false;

    nativeBuildInputs = lib.optionals stdenv.isLinux [
      pkg-config
    ];

    buildInputs = lib.optionals stdenv.isLinux [
      openssl
      zlib
    ];

    meta = {
      description = "MCP server for development in Rust";
      homepage = "https://github.com/Vaiz/rust-mcp-server";
      changelog = "https://github.com/Vaiz/rust-mcp-server/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.unlicense;
      mainProgram = pname;
    };
  }
