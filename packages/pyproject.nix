{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "pyproject";
    version = "0.1.1";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-+wdA13/wMErVl1u8r3YNtTPbXokFYC5qoVx3lmLXaNI=";
    };

    cargoHash = "sha256-Rcq6MsfnpcRYVrZnFKY543dXDN/zWMcEqFA8zH3zsSw=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/pyproject";
      license = lib.licenses.cc0;
      mainProgram = pname;
    };
  }
