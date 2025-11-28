{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "pyproject";
    version = "0.1.2";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-9i+XhEr+1aMdd4jCejNskXp5muopXG7rqzz1TeYRdqw=";
    };

    cargoHash = "sha256-WYTCybjRHG37afDPgboqRX5KNIIRuXzPNVO8RA+TIOw=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/pyproject";
      license = lib.licenses.cc0;
      mainProgram = pname;
    };
  }
