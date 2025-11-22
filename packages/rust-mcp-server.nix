{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "rust-mcp-server";
    version = "0.2.7";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-iPzG6yoxM+GxB6l27OrgAOlBxwDWhtNrlA/9GieU8rs=";
    };

    cargoHash = "sha256-s5xOEZftiBt1bo3rMo8HnP1kV2wy8fxfltQEE+5jX4c=";
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
