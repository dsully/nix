{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.11.0";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-Mz8mjDvY7YRFyrQiK61vZk1VGayMPMRPU1nlUAjBiv8=";
    };

    cargoHash = "sha256-X+0d2x2RYIQR/U3SYLYVl82LBlKh6BoFMSxqJGSuxUU=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
