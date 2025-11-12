{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "clean-dev-dirs";
    version = "2.2.0";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-q+VdfgljzLCkkiBnXDtu6A+2eGRN/UewQ3WUau7tg3g=";
    };

    cargoHash = "sha256-lp0ktfl+XWIISinUpYWac7yPNmbD8PruPpoIK/Y75ZI=";
    doCheck = false;

    meta = {
      description = "A fast and efficient CLI tool for recursively cleaning Rust target/ and Node.js node_modules/ directories to reclaim disk space";
      homepage = "https://github.com/TomPlanche/clean-dev-dirs";
      license = with lib.licenses; [asl20 mit];
      mainProgram = pname;
    };
  }
