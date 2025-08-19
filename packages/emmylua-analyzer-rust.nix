{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "fd31961abf8e090ec9c0fe113ccd095059f72791";
    pname = "emmylua-analyzer-rust";
    version = "0.10.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-BSAJG0QFlWR+t8r+1zPBQFWzmsH+jj5Dap7hfZ8yGCk=";
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
