{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "9ccde0b5d6b67c65e8cb40871edcfa778e1483cc";
    pname = "emmylua-analyzer-rust";
    version = "0.9.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-+iem390OAlsyOZedJgXLcYHyW/2XXdA75UFgbxPwbbs=";
    };

    cargoHash = "sha256-H9gb9hv6THoRisGsWc18KWzmF98Fff7MxakKOOKd46c=";
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
