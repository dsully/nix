{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.8.3";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-vxgKJT1N8IINYsrcSWB0blfPVXxpo7m/DpAGFxoT7tA=";
    };

    cargoHash = "sha256-MG4xBcRlNP0y743LoW9UzK3Ev/Rq2W/QAyp/2tmlFn0=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
