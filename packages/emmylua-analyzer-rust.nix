{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "cb88050f2b715e0376ba8acd86ce685fe7db56e8";
    pname = "emmylua-analyzer-rust";
    version = "0.13.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-XprcyPebHhqymD1/ZiwGnv1FzC6ITsuXlKLsABD/mAQ=";
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
