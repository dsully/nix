{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "7ee051cd155e2fa3801ae51b1c84ef09eb44035f";
    pname = "emmylua-analyzer-rust";
    version = "0.10.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-qAmm/jlaQx/9uZQQoZ6lKfzus8ekTemnkp1GonWzHSU=";
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
