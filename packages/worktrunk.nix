{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.15.1";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-htbxs0JYDUryk0Z2sTy7HqeS8wZ7oQQxG3ssI6EaPx4=";
    };

    cargoHash = "sha256-lvCLtBcLrliiko7ukMN3b6qqOSY/3H4Eq3vnCZit3mQ=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
