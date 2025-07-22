{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "b36890ef3eb776cde53c2d678baf45af150b7e65";
    pname = "emmylua-analyzer-rust";
    version = "0.9.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-WxZIh9FhZcColtXZMwB5j+BL4Tox8+TYhU9UWUCuirQ=";
    };

    cargoHash = "sha256-LQ1pCuGZnV+TrhKqoOaLALNGoju5mXeQKK9gLMM2uI8=";
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
