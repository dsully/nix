{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "rust-mcp-server";
    version = "0.3.5";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-3Y5ExN/KD2+sbKoov2GrOg7wCuptQK5ZozGTl8+dfUw=";
    };

    cargoHash = "sha256-8tV7dQ4VDea/aUJYKr94ZmLrgwY6+i1d+mQ1zrU6LEw=";
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
