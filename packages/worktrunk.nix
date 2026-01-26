{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.19.0";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-f5xGMSfSYx/yS/5ofCIXd8JZgY1W6c4C4afsRjqKQz0=";
    };

    cargoHash = "sha256-gw8ss2J9eRUHBTh/slDjHaYJQzPcYjusiwbwoal5VSU=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
