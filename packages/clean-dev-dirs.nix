{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "clean-dev-dirs";
    version = "2.5.4";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-rr5etNbdRMR58kFrLHXq3n78PlDKbY4C/CUxM0kPylc=";
    };

    cargoHash = "sha256-2BV2GT3L3oq4j51FolOCH6AvZwDWDeO1C7h75A58VbI=";
    doCheck = false;

    meta = {
      description = "A fast and efficient CLI tool for recursively cleaning Rust target/ and Node.js node_modules/ directories to reclaim disk space";
      homepage = "https://github.com/TomPlanche/clean-dev-dirs";
      license = with lib.licenses; [asl20 mit];
      mainProgram = pname;
    };
  }
