{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.5.1";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-O8rF0OqE8i9KYiDom3H/VzEOf8BcTD0vfbAjPQ9+uPg=";
    };

    cargoHash = "sha256-QNo9DaGXywfeLcKgi+B+E4kw8v494vnfm2phpKNvvX4=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
