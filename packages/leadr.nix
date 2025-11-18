{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "leadr";
    version = "2.8.3";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-3DYhtWUogQi4e06SMmXTFemI5ws3AYxFGjAfNIzs/nE=";
    };

    cargoHash = "sha256-T43EZbS9jmSrgbpjbzAuej93Y5g0qJpEyCcRnWge4w0=";
    doCheck = false;

    meta = {
      description = "Shell aliases on steroids";
      homepage = "https://crates.io/crates/leadr";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
