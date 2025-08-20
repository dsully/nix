{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "1b22ca7ae75d4f0bd662b71bda9b9f1c2c0a2c43";
    pname = "emmylua-analyzer-rust";
    version = "0.10.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-hZAOAtD0zCk12w5mWS0XZI7fvPp0nRXpyIjyY5t3ij0=";
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
