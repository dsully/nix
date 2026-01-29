{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.20.3";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-v0zOyQmHb/XtAEaEspVgQCfdEhiJd3RYj0c8IaotGoA=";
    };

    cargoHash = "sha256-bSa+gcs31D1IXb67rT0kWDeeql4vkjMtKhvrBYnXqZY=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
