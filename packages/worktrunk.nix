{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.29.4";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-00vXGB2l1bnTnKLw+jQc5tswL5fR3EN9BZuUhqOIz0w=";
    };

    cargoHash = "sha256-ggTb5k03lyyStMpe6H45XZA8iPZnNqkdxirnsybH2gg=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
