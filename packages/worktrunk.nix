{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.3.0";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-0CoB8xV2Y1I8nNHqePy2ZlB+sXGtCXovpTpikrL9j+0=";
    };

    cargoHash = "sha256-Xg0XOhqhTQqtVNkE25orGNiXHZwBI84tQypDIdjVrRc=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
