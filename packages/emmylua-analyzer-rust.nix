{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "99240982b06c9e8be2c8406b731b814493d8b494";
    pname = "emmylua-analyzer-rust";
    version = "0.9.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-ehNzEiNVYl3cJdk9A0rLxQ/H1hl8PNdvlMVXJue+2cQ=";
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
