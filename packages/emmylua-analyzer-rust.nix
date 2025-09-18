{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "58b3e839c5d26a1b85b529ed6d423ce07d24f6c9";
    pname = "emmylua-analyzer-rust";
    version = "0.13.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-pEVWz07aMPf3bVYP9joUueFXzejdOjnQBWWFpQ0JTyc=";
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
