{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.1.19";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-AmgtsvkDZlE1RotgU+R5QfbuyACjHcpNwEGUh08/+GA=";
    };

    cargoHash = "sha256-myOYV7OLxZjmKXzuemtyERMD7ZOiLbDaGMPxOcMNn7k=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
