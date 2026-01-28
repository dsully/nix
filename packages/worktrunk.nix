{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.20.2";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-zefnUF4LMIXteOzsORGJjvWNYxJAZTgZI3M2NRlW8fU=";
    };

    cargoHash = "sha256-i4c3+X0l6FWEcer42yLCzDZLogLuSkx6zo4kgnLRv+M=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
