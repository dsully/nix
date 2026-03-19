{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "treesitter-mcp";
  version = "0.6.0";

  src = fetchFromGitHub {
    owner = "Christoph";
    repo = "treesitter-mcp";
    rev = "1b3dedc5f46c2d281434b04a1327ad276dec0d60";
    hash = "sha256-rnjyvZBAnysNOkcPoQWqzwkC6+IKCDfLeBYKRj1vb20=";
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
