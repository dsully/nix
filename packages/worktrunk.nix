{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.9.2";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-hiA0P9BdWoL4uOeFsVfJyK1enRGUNkRGV9YDwLn68h0=";
    };

    cargoHash = "sha256-AyK9fjN8fcHZ2bHCy6Jw8tIkYXF56Zn9JoqBcqNwfL0=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
