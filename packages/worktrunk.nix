{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.1.20";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-8dtWRcxU/CHlvVLJgW0hqakpOWK3W6sXQuoew1694ko=";
    };

    cargoHash = "sha256-dxCwpDUgZDqObEyJMzmGKH430BwxqBX+oKMI+0Pg15Q=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
