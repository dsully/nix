{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.14.0";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-PYj5prFeCv3EBPcufBoINg5mqNZqLa+r6ScL18hYogE=";
    };

    cargoHash = "sha256-Yq+bsYQEkViLMK1J/DSf/WTBEf1+eU3GOvQQvgZbxxk=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
