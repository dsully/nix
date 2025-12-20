{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.5.2";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-S+xFaLh3DH+gtJFju4lBvYJUeNtTRV67IM7ml/F27es=";
    };

    cargoHash = "sha256-/2yHfMtyE0RM78cgIOsUZxAYKaIuximr2E6NOKqlJfI=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
