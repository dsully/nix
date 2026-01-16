{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.15.0";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-4FJEG+1rhz5bR+pO3FsKYde6M8lGB72R4kh+ndThYm4=";
    };

    cargoHash = "sha256-o4+FSeGjMg21yfbW5EnUuDbiYb9/zvdA+dvUN7YBVWU=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
