{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.13.2";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-8kvcw1xzjjveC/BHQBc0fW3O2ny6OhklyMg/YkJ3gE0=";
    };

    cargoHash = "sha256-05eKa8RI3yBUEIMylDW0l9GfpTNenFet/9eNvDlMne8=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
