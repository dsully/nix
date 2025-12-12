{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.1.21";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-sp43EZNNR1Hhir/F9AocxChWQIQElQ+s/nRBNrO7BJo=";
    };

    cargoHash = "sha256-jfrWeHhmKJjsKYZy7njh50S1+5lnQzpeCtsgZMvCiqs=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
