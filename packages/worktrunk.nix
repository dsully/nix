{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.9.1";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-As0P3h8fffxyBZ4hKi0hkeTpD4LE1Vmph1nVHZR2bg0=";
    };

    cargoHash = "sha256-V4BQ80OXRfqNkA+9inPj4S6NWl2SbIekawMb+3OgAYI=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
