{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.1.18";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-d/W4wuVGcq1ytafQ0NbhUeSRDGjP33Usy2eED0YhhcY=";
    };

    cargoHash = "sha256-97qtKfl4L0Vq1Q1ufTtLh4pFAlTswH5bdEucNxRSASo=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
