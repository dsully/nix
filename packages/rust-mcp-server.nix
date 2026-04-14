{
  lib,
  rustPlatform,
  fetchCrate,
  pkg-config,
  openssl,
  zlib,
  stdenv,
}:
rustPlatform.buildRustPackage rec {
  pname = "rust-mcp-server";
  version = "0.3.7";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-137J1yF9IPhO7lBBqjRWJjltqD1vnT/R8DY65FLDR8A=";
  };

  cargoHash = "sha256-DDfdAnu2WBno+jmMknmyeyJuuhChTEElnCN8aYdIxP4=";
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
