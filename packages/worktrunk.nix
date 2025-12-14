{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.3.1";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-IaRplQsuXjNOk0+xKEdpx1hpphmUKWL9WQwrTSs2d9Y=";
    };

    cargoHash = "sha256-S1btuaAceSGExF2UAmVp6W3Yli0KmH90tlRYf8w+quI=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
