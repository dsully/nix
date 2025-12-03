{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.1.12";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-xJwhgrcBMUCpaRMOrLa5c5lUDKwQ/4Yp23YCLNPsqKg=";
    };

    cargoHash = "sha256-C988dtnL15QdFA3bQJ9w5+K1hVrFqM71ul61PeojYzM=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
