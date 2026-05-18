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
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "DisturbedOcean";
    repo = "codebase-mcp";
    rev = "4e1508324b9ec89a654988b38a79a175b893a789";
    hash = "sha256-yrtdilQeLvmyXTUgtp5tZOPp2xuUFj3An2f4oPZfVlw=";
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
}
