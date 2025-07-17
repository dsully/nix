{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "f6c88f9cdd0a526d0eff01470a080dc72f09fe23";
    pname = "emmylua-analyzer-rust";
    version = "0.9.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-x1MTXxxSj/pRqJJftCZw8w6auw+lXbit+MUy46tVChM=";
    };

    cargoHash = "sha256-In1fTvGpt3d6VfSoAXVrdkkIzRRyBlV97NXOvefIOZc=";
    useFetchCargoVendor = true;
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
