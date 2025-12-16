{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.5.0";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-7YdmV+8sS4omTI5zashiOsBPHWAbydNlMi5sEeyGJa8=";
    };

    cargoHash = "sha256-qLr/AuuWMLaENWC+mFQ/wTUo0cyIHm+ebYtmFRuvgAs=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
