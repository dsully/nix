{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  zstd,
}:
rustPlatform.buildRustPackage rec {
  pname = "codeloupe-mcp";
  version = "1.4.1";

  src = fetchFromGitHub {
    owner = "ndhkaeru";
    repo = "codeloupe-mcp";
    rev = "b2113628c784b5ebf0c654eae89288e337edfdc3";
    hash = "sha256-t1OMBO5p4/upHtbSc45K9fIwg4DRrcilvUWF8DSGtZw=";
  };

  cargoHash = "sha256-gpVMflmVY3/0ckPTu3L77nxIXnFIvkQqa4Qqzwg3jpI=";
  doCheck = false;

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    zstd
  ];

  env = {
    ZSTD_SYS_USE_PKG_CONFIG = true;
  };

  meta = {
    description = "A local-first MCP server for real codebases with 37 tools";
    homepage = "https://github.com/ndhkaeru/codeloupe-mcp";
    license = lib.licenses.asl20;
    mainProgram = pname;
  };
}
