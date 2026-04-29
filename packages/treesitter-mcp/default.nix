{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "treesitter-mcp";
  version = "0.7.0";

  src = fetchFromGitHub {
    owner = "Christoph";
    repo = "treesitter-mcp";
    rev = "97bb2fe35bcc7a63a6afc940aa6cbe6670b40ec1";
    hash = "sha256-wZgta/NQEUKF6c0SQ+65EwUzb+MUPMgmB/W9c/D5KFA=";
  };

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  doCheck = false;

  postPatch = ''
    ln -s ${./Cargo.lock} Cargo.lock
  '';

  meta = {
    description = "Tree-sitter MCP Server exposes powerful code analysis tools through the MCP protocol";
    homepage = "https://github.com/Christoph/treesitter-mcp";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
