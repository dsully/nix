{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "7f849642615141d451b22d1795925be3d64bcd9d";
    pname = "emmylua-analyzer-rust";
    version = "0.10.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-5JTTVX3ZLDa9IEWy9c7k5qhwrsRz6Eeg8EmrT94NGwY=";
    };

    cargoHash = "sha256-wlzklFNuQrhu2PwzUe26sCU8gSb0uIobi0Vhw7S3JD0=";
    doCheck = false;

    nativeBuildInputs = [
      pkg-config
    ];

    meta = {
      description = "";
      homepage = "https://github.com/EmmyLuaLs/emmylua-analyzer-rust/";
      changelog = "https://github.com/EmmyLuaLs/emmylua-analyzer-rust/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mit;
      mainProgram = "emmylua_ls";
    };
  }
