{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.18.0";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-LLC7gvZI+Rzlxb9T01/Ks2piUxbcrDgCV21kfnZCP2Y=";
    };

    cargoHash = "sha256-j34EFKVqzCFCV+sEWIUfKD02x74sIysNNjGR6YDJPaI=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
