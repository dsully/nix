{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.10.0";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-wFdbSfS3Aqxcby2YXrpOx2pbBWaOf//VDGma3aQj9Ts=";
    };

    cargoHash = "sha256-eZ9mmx8kVTvYwsjYzV2gdJLyUhToyBeYw7XFE5yeguM=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
