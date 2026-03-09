{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.29.0";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-CE8zM5yrhI2fGnD1xJWw7lkrrsK4JRVhTFf0T65BKEA=";
    };

    cargoHash = "sha256-tcMIssZJ87pw/CqHUzZcU+LgozzxSEionLqwssI9H90=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
