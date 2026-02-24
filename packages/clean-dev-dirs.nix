{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "clean-dev-dirs";
    version = "2.5.3";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-X4hxvLBoo4QcQmQkc/GEoUKcO1hHJojUwWHVGdxMf08=";
    };

    cargoHash = "";
    doCheck = false;

    meta = {
      description = "A fast and efficient CLI tool for recursively cleaning Rust target/ and Node.js node_modules/ directories to reclaim disk space";
      homepage = "https://github.com/TomPlanche/clean-dev-dirs";
      license = with lib.licenses; [asl20 mit];
      mainProgram = pname;
    };
  }
