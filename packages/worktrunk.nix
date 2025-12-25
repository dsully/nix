{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.6.1";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-of6fiFMrX1WCe3o6gQa22tQjtzy+uZNy/Ptv0SXN8jE=";
    };

    cargoHash = "sha256-7za+23nLUQTNPgpBsS/7Tdgguf/q1NyqIZwIxnaiQrk=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
