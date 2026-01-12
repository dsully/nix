{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.12.0";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-sXxDgq3zAV4j4H3G0rXly8OFRUxNgF5X0NsT/0mdBYU=";
    };

    cargoHash = "sha256-cJfSdg2X8TJ17NshS19C1ztH9s37k4NFsCpCaW+1av0=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
