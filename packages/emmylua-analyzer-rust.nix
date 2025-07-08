{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "emmylua-analyzer-rust";
    version = "0.8.2";

    src = fetchFromGitHub {
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      rev = "94f5a50c6f01f74b358b6bad913b6376e29f2057";
      hash = "sha256-MJcRThsUyq4hlSefqex2fV9XRgix8qviTBTTDqBiGnw=";
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
