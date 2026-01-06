{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.9.4";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-2tMUDta5X3RzyRrvnvIMLtUmE5hXQJAejNpUP6P2YeM=";
    };

    cargoHash = "sha256-VWfVGcdhZqsRbgny8oCrt1iyYrbj0PK+HKD9chBoxeY=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
