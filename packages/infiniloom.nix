{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "infiniloom";
    version = "0.6.0";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-hH/3UdPoNnCgOjhkk+j30LAJG23XLhjJHEiKGMGW1zQ=";
    };

    cargoHash = "sha256-EZobEMN9/XNnjOWHqRVRIPoNqsZgJTkoTAUn+tLD5ic=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/infiniloom";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
