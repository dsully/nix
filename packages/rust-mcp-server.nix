{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "rust-mcp-server";
    version = "0.3.0";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-EYqCkvoE55VusA+jEOTVplYIk+G5//AVTqohVhq/41A=";
    };

    cargoHash = "sha256-/muf/xnL/J5UhemAbH0ZlqU7URzPid4YuU4YkfesHyE=";
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
      homepage = "https://crates.io/crates/rust-mcp-server";
      changelog = "https://github.com/Vaiz/rust-mcp-server/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.unlicense;
      mainProgram = pname;
    };
  }
