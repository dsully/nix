{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.4.0";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-8MWY0TpaqUfXm8D5PgOHKGb6YBxZl/9gnAZq2ekuhYI=";
    };

    cargoHash = "sha256-iTI92njKU5n/stVZB/SpZvfPboNlZnNE+MGOXZeURCk=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
