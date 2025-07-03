{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "emmylua-analyzer-rust";
    version = "0.8.2";

    src = fetchFromGitHub {
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      rev = "e8604aca29f14d00a388e4b0134dd805695f6be4";
      hash = "sha256-rykGXLytXa7ndzhjWSOLbxQxgFnuyFtwdeHyHhVaKIQ=";
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
