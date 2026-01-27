{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.20.1";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-x4NkAJTn75ZO1sEJwk//S4rpvld7MWvkCdVJ2OlbtqI=";
    };

    cargoHash = "sha256-sa8iAMcGXaH+24I78AyEMaHxOwPjX2gjQcOcqaOs784=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
