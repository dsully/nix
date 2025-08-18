{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "451b160ea99307a53feb6e90f455e2cbb95f1d32";
    pname = "emmylua-analyzer-rust";
    version = "0.10.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-f0UwaDc2IJHHOnlK22kBk8qMgSEn2WlsrNziHIrc6PU=";
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
      mainProgram = "emmylua_ls";
    };
  }
