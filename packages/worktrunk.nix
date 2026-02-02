{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.22.0";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-00isK/yHLwDISW58/Z7b7Ppr23tL3Yjfhkmr37G9l3c=";
    };

    cargoHash = "sha256-Hz1r6oBD+QTvNbmX68jvn61GqRlD9FcuIuY6o+Y5jWQ=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
