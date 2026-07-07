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
  version = "1.4.1";

  src = fetchFromGitHub {
    owner = "ndhkaeru";
    repo = "codebase-mcp";
    rev = "acfc7e6fd2fdc9dbe9fc68c6262e7770546c1aaf";
    hash = "sha256-/LX+G4Vv8cJ99AbtgHIBpd7boTZYSoV6teIbW+UDIzs=";
  };

  cargoHash = "sha256-ulhEWqfIHYVzK3o80BSJ3r8MBgDpqSYunQV4+lGui8k=";
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
