{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.23.1";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-lhDB6ZY2E+9uOEqqzYPNcw0ZVwB/XdGcZ0X/8rKABeo=";
    };

    cargoHash = "sha256-1Zk/6IoBlolmw9TaoF46YZv43+iDBKY16oDSCmwmTL8=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
