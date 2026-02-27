{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.28.0";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-HcU2ZlIoMLCdPMHgGpPi54zD1xJFUduifhrEf8WAEJs=";
    };

    cargoHash = "sha256-0P/3Hc+5A2rKGYLB9BGmP51oC1SE/43zrc8tU134QrM=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
