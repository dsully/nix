{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "infiniloom";
    version = "0.4.11";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-USmZPNT3DnaEmwsX2KZ1y1qzijNb1xidKFfSA2h5tYg=";
    };

    cargoHash = "sha256-qtwVQICqmcHwf+DftSQcnu8UHcgcps7DPVnrgmeHQ64=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/infiniloom";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
