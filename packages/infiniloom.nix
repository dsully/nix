{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "infiniloom";
    version = "0.5.3";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-KMJZyeJhpLb+0pPYOCA+ygslnKO7vaCKEpBFR+G/L0g=";
    };

    cargoHash = "sha256-jUUhYjyVdY4BTbpe0zTbLJwmV4SoyXi3L1o4ZLgmqYc=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/infiniloom";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
