{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  sqlite,
  zstd,
}:
rustPlatform.buildRustPackage rec {
  pname = "codebase-mcp";
  version = "1.4.0";

  src = fetchFromGitHub {
    owner = "ndhkaeru";
    repo = "codebase-mcp";
    rev = "d9aae1e1e58e882adffeaf165c96dea19973ec63";
    hash = "sha256-5BZHoimwoPs0K00zYkA3k9XgBkfTqAQ3GUliTLuOjJ4=";
  };

  cargoHash = "sha256-BuEW1Mpgn9RiznQycBl2deg62r5pULrhl9Frpo8Je70=";
  doCheck = false;

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    sqlite
    zstd
  ];

  env = {
    ZSTD_SYS_USE_PKG_CONFIG = true;
  };

  meta = {
    description = "A local-first MCP server for real codebases with 37 tools";
    homepage = "https://github.com/ndhkaeru/codebase-mcp";
    license = lib.licenses.asl20;
    mainProgram = pname;
  };
}
