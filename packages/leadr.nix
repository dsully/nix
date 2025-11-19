{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "leadr";
    version = "2.8.4";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-IOJ2B0+XzuUZCIRe+MDSNofFRWV/+tLOW29H4TDZ29s=";
    };

    cargoHash = "sha256-+R2g2AkILPjAHD8WqcKyNm7KN9XBjvjk0LasPpqsbbY=";
    doCheck = false;

    meta = {
      description = "Shell aliases on steroids";
      homepage = "https://crates.io/crates/leadr";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
