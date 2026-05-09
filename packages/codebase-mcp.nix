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
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "DisturbedOcean";
    repo = "codebase-mcp";
    rev = "0e788371695f5346765cd2cc1ac94ea53ea2bfb9";
    hash = "sha256-3ZiPM3ZJ87SXHFqwaMVpjJgtiTcBDwYSfVrFrLb02oI=";
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
