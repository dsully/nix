{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "0e11e22d9cf31612bb93695c0efb97133ba49cb2";
    pname = "emmylua-analyzer-rust";
    version = "0.10.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-gSO+Kv0NOzx2eB+ybt/rTKiNNBRxnS2WbrkZ2kZz3Tw=";
    };

    cargoHash = "sha256-MIGYx1qMxsCCq3QkFeOuKbM4w/sJ2K0T+SRIDJQjf/8=";
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
