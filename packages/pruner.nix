{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  zstd,
}:
rustPlatform.buildRustPackage rec {
  pname = "pruner";
  rev = "5a878e955fb2a565134a206a50bc2f2b56a86aff";
  version = "1.0.0-alpha.9-${rev}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "pruner-formatter";
    repo = "pruner";
    hash = "sha256-758ViC0AzKgV8p9HoMD4XlKFFrE75NoqQSosIyjetYg=";
  };

  cargoHash = "sha256-vbA4M/DBmy5JZ5D2quixcVWaIm1MRHl2cYyKhzvkftI=";
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
    description = "A TreeSitter-powered formatter orchestrator";
    homepage = "https://github.com/pruner-formatter/pruner";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [dsully];
    mainProgram = pname;
  };
}
