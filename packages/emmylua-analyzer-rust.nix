{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "emmylua-analyzer-rust";
    version = "0.8.2";

    src = fetchFromGitHub {
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      rev = "8a629f239e85ad09e4e3d9f4e8da4e268842fe50";
      hash = "sha256-GJjGVmM2jHK75er5rKVSiilzGi4BffBCm3IzS9IQrMA=";
    };

    cargoHash = "sha256-I5h63A8hAmeQfy0E7zNm91YEUxa7iLNR3o4yMLpvdd4=";
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
