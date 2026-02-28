{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.28.1";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-9lpbuYe4H/3aLLEteIAtoF8Rd1PCiu93trWg97YeS2w=";
    };

    cargoHash = "sha256-Q28XcD2EhIKOBBNqFvWCx4fn4DaIJ45u/L6CYW9fyGE=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
