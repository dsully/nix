{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.18.2";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-izOpjBV9Osmjis2VBhDGC874yb0qAz5Ynxctp9Wh0Fg=";
    };

    cargoHash = "sha256-bB6Jc5X81+S2iY4zYH2wa6HuhhQQKwSau+f28GhuVKw=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
