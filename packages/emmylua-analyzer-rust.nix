{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "emmylua-analyzer-rust";
    version = "0.8.2";

    src = fetchFromGitHub {
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      rev = "04804de6dd44f282b30fa923836214cad6a81e79";
      hash = "sha256-A+JGlL2XC2WayENqk0qn2U/N6wQ5DWmYaJLuE9ZHNdw=";
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
