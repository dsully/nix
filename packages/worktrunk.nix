{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.14.1";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-w2lpGU4uNEGJDGdQtblmvRFw7yCBIXAwGCRa5Vi6eEA=";
    };

    cargoHash = "sha256-MHNtU+ZaWbdpdAMf12VMODcSwGhHeHmbKnLnQBn8X9g=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
