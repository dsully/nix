{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.24.0";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-8tf3kCCTj01a8zDb2DXgLUZUIP5AKKiAGtoZDfdM4t4=";
    };

    cargoHash = "sha256-MNoZqKg7RioNAp2Y9J1LIa68mBRdcROuDn4wJihuWN4=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
