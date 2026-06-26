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
  version = "1.3.2";

  src = fetchFromGitHub {
    owner = "ndhkaeru";
    repo = "codebase-mcp";
    rev = "562dde685ea62f16f0c3f3692d064919f47b11d6";
    hash = "sha256-CJLpfmY6NlySCRsBRayWHaEyM2+6ZAoOVDP2WARm6Jw=";
  };

  cargoHash = "sha256-pih83ikcapNDfXfo+Ri7h3NexwVC35iA2x9eqbKqoaA=";
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
