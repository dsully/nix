{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "b18428833d643352d6cf8e71037acee05f9e0e0d";
    pname = "emmylua-analyzer-rust";
    version = "0.9.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-B11lK4xJo+NSgdIlW9I/AQ90HSskWPEUMHo6qQXdJl4=";
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
