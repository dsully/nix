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
  version = "1.3.1";

  src = fetchFromGitHub {
    owner = "ndhkaeru";
    repo = "codebase-mcp";
    rev = "48b30f15a64fdfbea15c5005e3dac2627b2113a0";
    hash = "sha256-tTD1ulW+iqqg5N/uNlCizBrKf1td7iGgsSWi/j2cUdY=";
  };

  cargoHash = "sha256-8nLQ2uZUE09bV5qDrKUGu2fhpz97lSTiuDYgHc74jsQ=";
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
