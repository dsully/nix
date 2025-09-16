{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "e8aee814ab141cc430b6d5bfadfc9f0858d95335";
    pname = "emmylua-analyzer-rust";
    version = "0.13.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-lalxTTU5j5/qzmDUryxEWnsPd4eBfDibKrKDIy0BuZw=";
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
