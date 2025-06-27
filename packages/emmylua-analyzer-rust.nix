{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "emmylua-analyzer-rust";
    version = "0.8.1";

    src = fetchFromGitHub {
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      rev = "c10aa1185ff84c83a3efb2a5b8dddfd70cbbf28e";
      hash = "sha256-i9sDlp87nUMwvS5sJhqppg/CDLLfr7+tkwfMlfZHnY8=";
    };

    cargoHash = "sha256-vHEbjJKW6F09skFocK+qPJRp2jXQaIiDhX5v3nQuOos=";
    useFetchCargoVendor = true;
    doCheck = false;

    nativeBuildInputs = [
      pkg-config
    ];

    meta = {
      description = "";
      homepage = "https://github.com/EmmyLuaLs/emmylua-analyzer-rust/";
      changelog = "https://github.com/EmmyLuaLs/emmylua-analyzer-rust/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mit;
    };
  }
