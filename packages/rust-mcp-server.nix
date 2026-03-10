{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "rust-mcp-server";
    version = "0.3.6";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-VnKFOSGm5LFVV2vU/Rv8oTdS4605Ld6LeZfBsOXdW1M=";
    };

    cargoHash = "sha256-acR6hs/OhVEG87b8BrX62VV64lahexQoJlpPU3ue6nM=";
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
