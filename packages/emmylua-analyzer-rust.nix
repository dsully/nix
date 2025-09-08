{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "5682e6fba8c4b0a9a7b2ce46776a3d8583911071";
    pname = "emmylua-analyzer-rust";
    version = "0.12.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-RRpHzGj42cvdIQOqUtuHAbIkreCzJDGI51wjFM5/ApE=";
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
