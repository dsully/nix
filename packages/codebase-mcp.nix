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
  version = "1.2.1";

  src = fetchFromGitHub {
    owner = "ndhkaeru";
    repo = "codebase-mcp";
    rev = "bfa4cd9705c05a02c6da7735f4ce817010089839";
    hash = "sha256-aII4TQaoPKaa4iZHi4bKspJ/i/vDP2dyUWZ+cKQy9jc=";
  };

  cargoHash = "sha256-ePvZRo1VaGrfBnpaGv2ZEf/KRoxA4HZbjzvjuJYRD8k=";
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
