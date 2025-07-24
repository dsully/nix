{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "07fbea4454e67294cdc6ec98ec4e64fe510bec51";
    pname = "emmylua-analyzer-rust";
    version = "0.9.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "EmmyLuaLs";
      repo = "emmylua-analyzer-rust";
      hash = "sha256-t6dLq90yZUxpaM7d8a6JdDOoFSATyZA833rjLai6K8U=";
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
