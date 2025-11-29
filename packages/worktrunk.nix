{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.1.10";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-sfCJMtNwzcXFtjZbcHry00Vaj4W9qWZ+jy82tkDGO/Y=";
    };

    cargoHash = "sha256-fIalf19wtO+m3F3WUZewNk5+4JOdINMXsww691+JH80=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
