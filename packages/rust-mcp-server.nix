{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "rust-mcp-server";
    version = "0.2.7";

    src = fetchFromGitHub {
      owner = "Vaiz";
      repo = pname;
      rev = "v${version}";
      hash = "sha256-8L4VCSonzw+ONVvEdNfS8PYyzSfDsp9AditGWfz9xow=";
    };

    cargoHash = "sha256-s5xOEZftiBt1bo3rMo8HnP1kV2wy8fxfltQEE+5jX4c=";
    doCheck = false;

    meta = {
      description = "MCP server for development in Rust";
      homepage = "https://github.com/Vaiz/rust-mcp-server";
      changelog = "https://github.com/Vaiz/rust-mcp-server/blob/${src.rev}/CHANGELOG.md";
      mainProgram = pname;
    };
  }
