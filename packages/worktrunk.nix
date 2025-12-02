{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.1.11";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-wr9AiaQgS1dc6BZg93hClHdAfRwxoHvufC3GPaanlvY=";
    };

    cargoHash = "sha256-UknvbjdM+7HcPCBYNUFs51/tnz0W7hbp83rcB4v4uro=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
