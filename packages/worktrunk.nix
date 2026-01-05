{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.9.3";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-2S34vaIuP2xfnFYbiK3bEMyCILtYg0HpYc08BzpzgZI=";
    };

    cargoHash = "sha256-tjgA6DNtCqRA9HeVGUbyBx3OoZX43vrj33IhXN6t/U4=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
