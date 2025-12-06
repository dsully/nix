{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.1.13";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-5l0PyMtyRzCXGtTpgVhFn5BqWA+qHxcJ6QSOP/IhBFE=";
    };

    cargoHash = "sha256-VorPk3Gze/MuhOArgrgfn4Wps5cxBq/MBDpl2bdlYz0=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
