{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.25.0";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-Q0tL+b8LNo7a7zFoZkp7raqPtj+JBUzZE2rtULmYgLg=";
    };

    cargoHash = "sha256-Anj6SsKn6CBZof/faDoEFQXbHXHnbYd9jQsclZoettY=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
