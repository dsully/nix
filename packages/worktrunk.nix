{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.23.3";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-4nitPXuSvuTksQGCrkkPTQZDLm87gbPLRxgB95nVCVw=";
    };

    cargoHash = "sha256-rntixZyiSe6MXj0v/VZ3NS2jFrHbpPyZ9RP8sSdtPz8=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
