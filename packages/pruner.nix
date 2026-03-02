{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "pruner";
    rev = "577cf6d2d49dbe773512f83e1c1365efddb27c1b";
    version = "1.0.0-alpha.9-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "pruner-formatter";
      repo = "pruner";
      hash = "sha256-1vicEI84f7wGU0/0tEDN6EImkjVX0/SJIMASzrvZEPk=";
    };

    cargoHash = "sha256-8T4v3QZk1PNFCvgAa6q+fXCXuasPE8miGuM84MftbGU=";
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
