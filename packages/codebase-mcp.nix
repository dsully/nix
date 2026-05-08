{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  sqlite,
  zstd,
}:
rustPlatform.buildRustPackage (finalAttrs: rec {
  pname = "codebase-mcp";
  version = "1.2.1";

  src = fetchFromGitHub {
    owner = "DisturbedOcean";
    repo = "codebase-mcp";
    rev = "7648cb155a1e6b574bb8bd7054ea1e643fe70351";
    hash = "sha256-Q9VBjwdKN2/VFxF7oQxmN8KgDiJFdnPM3fBOhxSf+Vw=";
  };

  cargoHash = "sha256-wBweOPf0ZL55S/MsXx3e6/a+cDgj1qBqYBjWYI9wWIc=";
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
    homepage = "https://github.com/DisturbedOcean/codebase-mcp";
    license = lib.licenses.asl20;
    mainProgram = pname;
  };
})
