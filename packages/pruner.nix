{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "pruner";
    rev = "fdd3ba7632353a72d16f4c354c3c8bfed062ef9a";
    version = "1.0.0-alpha.9-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "pruner-formatter";
      repo = "pruner";
      hash = "sha256-IXI6S2r7spaUTkdOzkL1BWMQ9gXWejpM5b5Fn3UY7s0=";
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
