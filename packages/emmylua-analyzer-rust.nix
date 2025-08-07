{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "93abfc88407ec43d88c08f368ee9cd4f9e5f4309";
    pname = "emmylua-analyzer-rust";
    version = "0.10.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-0gmYiZvLE7dgw7qtTuhBLgAoUIRB3BjuicHWHGFBFGM=";
    };

    cargoHash = "sha256-C3YomgOy4sCUm/LGUcXtxBiTWlFxrO651MSR/QpWbGY=";
    doCheck = false;

    nativeBuildInputs = [
      pkg-config
    ];

    meta = {
      description = "";
      homepage = "https://github.com/EmmyLuaLs/emmylua-analyzer-rust/";
      changelog = "https://github.com/EmmyLuaLs/emmylua-analyzer-rust/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mit;
    };
  }
