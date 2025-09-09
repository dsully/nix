{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "08a53946831593164a7abdf1eff4153fd4c431dc";
    pname = "emmylua-analyzer-rust";
    version = "0.13.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-m1Tp4v3bVfoBpYCYLPYUA9VV4eXr8E1rjQ5QYgEDL/Q=";
    };

    cargoHash = "sha256-SbsYlIVWDpBU2bxJqXUtOiMHkOoa8Up27X7rVKLLLm0=";
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
