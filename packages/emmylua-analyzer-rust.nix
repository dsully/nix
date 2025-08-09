{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "5c6f4e1394e8d06b9d269a789ca1e010cfb96081";
    pname = "emmylua-analyzer-rust";
    version = "0.10.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-ZXw634KjbLtw0Sg6nwMyfKEhm2fJlxumnJ2qaBtxmfs=";
    };

    cargoHash = "sha256-3x71VNWCTFb75STx8w/T++dLo1s2FwNhFm+lyZHS7qI=";
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
