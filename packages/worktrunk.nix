{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.8.5";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-J3hspnSZHvvEQj5U3WQ3sn8fak8FNwpUfha7fp6CTD4=";
    };

    cargoHash = "sha256-FfrB85WIuSGCEq7CjGCf2awHfw/tMHFramzCzcE1TKg=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
