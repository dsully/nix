{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "rust-mcp-server";
    rev = "6d39ee74ca0429bb652e28638e0e56dd2f9b24c0";
    version = "0.2.7";

    src = fetchFromGitHub {
      inherit rev;
      owner = "Vaiz";
      repo = pname;
      hash = "sha256-8L4VCSonzw+ONVvEdNfS8PYyzSfDsp9AditGWfz9xow=";
    };

    cargoHash = "sha256-s5xOEZftiBt1bo3rMo8HnP1kV2wy8fxfltQEE+5jX4c=";
    doCheck = false;

    nativeBuildInputs = [
      pkg-config
    ];

    buildInputs = [
      openssl
      zlib
    ];

    meta = {
      description = "MCP server for development in Rust";
      homepage = "https://github.com/Vaiz/rust-mcp-server";
      changelog = "https://github.com/Vaiz/rust-mcp-server/blob/${src.rev}/CHANGELOG.md";
      mainProgram = pname;
    };
  }
