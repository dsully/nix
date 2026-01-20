{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.17.0";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-UMTF9m5WbVqtI7gEYEu9reJNRFJWW/g/S+I4yZdrjrU=";
    };

    cargoHash = "sha256-NMrCCEXcto+ciLbN5Qxm9TK1atibcElv5a3UI0WxADo=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
