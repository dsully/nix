{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.7.0";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-gIuJNF+KMWtPaH34/794uyzk5B5W0jzxe9YaZKdjTH4=";
    };

    cargoHash = "sha256-YerotbgnOJsFKiWvLi0ClcHxSTHvrhYwnLsQA+bNQRg=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
