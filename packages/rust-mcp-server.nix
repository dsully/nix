{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "rust-mcp-server";
    version = "0.3.3";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-+pXqK2fv2b3MNBuu1GgXAZuirSaO1ala1BXZSvYJNy0=";
    };

    cargoHash = "sha256-9o6dyOR+R6Pz7v1tsq3vP5KjCu2wT/ALnNFjuhuETdY=";
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
