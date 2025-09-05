{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "96e3ce2d022919cffbc318f3cbe32534c382e310";
    pname = "emmylua-analyzer-rust";
    version = "0.12.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-93PlsVvlUravsnW7YBCii04jCEJPP+6U2vYbVBjcX8M=";
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
