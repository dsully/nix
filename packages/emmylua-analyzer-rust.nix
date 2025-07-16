{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "2f2217ffefd543d1da7c410e52a093b1482ceec4";
    pname = "emmylua-analyzer-rust";
    version = "0.9.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-CpOaRPL8Gaf/cuMlpzf4ovRZ2FptZMUDkTT/rp/Jqjg=";
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
