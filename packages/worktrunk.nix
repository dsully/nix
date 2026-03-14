{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.29.3";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-OiQGOLlNNf5IwtqYWmcdo7sXCu5Didc68x8S0HTZZOQ=";
    };

    cargoHash = "sha256-dMWGR9p40l5NcPhSzJOIz7pG+5oa/c5oVHHxznukXfQ=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
