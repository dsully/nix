{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "f4418548d996f21130f330eb4545cd99391b2003";
    pname = "emmylua-analyzer-rust";
    version = "0.13.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-20tiijpdw2ZlTB7s2lacQuN56pZSRhD6MgTZzyujhSs=";
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
