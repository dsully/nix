{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.28.2";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-D+3FdVdIK+nF8S3EaoT9LZ1JtLtV5Un5wCQ5qfNzubs=";
    };

    cargoHash = "sha256-HaxbSITlSGHRPK6NMPh0szMTwF6FKN6T1RHQ24JF/N8=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
