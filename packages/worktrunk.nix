{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.29.1";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-TtJ5j9ZluNZpZn8IijAnC0V+Qjw52LVJccNCUgRBGJI=";
    };

    cargoHash = "sha256-SWptf7XTDWSJH6zBE5N9V7zg7i9M3QlLFKJIKwF7d5M=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
