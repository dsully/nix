{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "rust-mcp-server";
    version = "0.3.2";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-34ZrgLsfEbGUWkqAuhWvW2WviSNIw+p9PE7DJSKDr+g=";
    };

    cargoHash = "sha256-z732tS524RY5nqyciJCzvOq4v5XXsFv48F9nNEpmThI=";
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
