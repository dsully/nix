{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "e07b5e2240eebf5954ab41f772d6f550788a9f5d";
    pname = "emmylua-analyzer-rust";
    version = "0.9.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-sSHFqTa1couw7oU2tou/qn6fewG+FpQdK3Qm9Rr24zU=";
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
