{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.23.2";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-ohJuu9y4ibXn3tkPJOyN3v3Ml8QWkYLBS5mYWvwxSII=";
    };

    cargoHash = "sha256-/qmX+b9aU84ipNL9noQ0xtXyxshd07hAgYGPBBx5mwg=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
