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
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "ndhkaeru";
    repo = "codebase-mcp";
    rev = "2a675201e6ab1a3e5a68134b99bbdbda1309d99f";
    hash = "sha256-94v1H3+qi6dYJHcoMf3pI+dNW1dA9XNwgSVjvgF7kiI=";
  };

  cargoHash = "sha256-Qln6bCch8eErKocOgowRcIGEgknTYpXKLRgmzkVUAxA=";
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
