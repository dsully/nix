{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.8.2";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-NDHZ0fnBT2c6DH9ZLwwRZA+CVrBhgKECV7Pz4dNAAZk=";
    };

    cargoHash = "sha256-e6tuogyZO5pG35KrQxWmsW5g/PvQniGumBkfa17VjUc=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
