{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.26.1";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-oq5Ps9+lSJCFEN1xa21peohm+HlKCzGtpY5tyicBXQw=";
    };

    cargoHash = "sha256-GeAz/CI3v4ziBv200mdlSYNWlyjJ5brO4Q/3Z3Xsygs=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
