{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "mcp-rust-builder";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "CeeArEx";
    repo = "mcp-rust-builder";
    rev = "91e26d447af94ce47859ab97e1d4ab2b78cbfd5e";
    hash = "sha256-CRH0WneiRQxNn/MCapEsyk8fWbkh5Bap/qGU+dF67k0=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  doCheck = false;

  postPatch = ''
    ln -s ${./Cargo.lock} Cargo.lock
  '';

  meta = {
    description = "A specialized Model Context Protocol (MCP) server designed to scaffold, build, and debug new MCP servers in Rust.";
    homepage = "https://github.com/CeeArEx/mcp-rust-builder";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
