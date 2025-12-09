{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.1.16";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-TzdQcA4qCZ7swGtWGGwpnY8Yj4lNtlGG+bwzL0+si4o=";
    };

    cargoHash = "sha256-DdwKpyUYUnFZO6zLZf0D4MK3wSES1uV21+OiWS7FX3E=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
