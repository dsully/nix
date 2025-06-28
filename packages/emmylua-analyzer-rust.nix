{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "emmylua-analyzer-rust";
    version = "0.8.2";

    src = fetchFromGitHub {
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      rev = "6cc7f6295c546071eb946529d879a71aff56133d";
      hash = "sha256-8mv2BIFerP0jD/mSL7Ukidf1aupH74Ae77cUA6VB1Cg=";
    };

    cargoHash = "sha256-m8WLUcGgNwNcEdKgsAsM6U1deQb/zaYV64vJYfogZHg=";
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
