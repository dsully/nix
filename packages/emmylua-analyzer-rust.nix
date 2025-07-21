{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "caf99943558f9bc388e5b6a16f6b6bdd1bb94f18";
    pname = "emmylua-analyzer-rust";
    version = "0.9.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-oshIt9GtD2sz/Byt0KnP6Po248f/xOnWvft/UiAy4P8=";
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
