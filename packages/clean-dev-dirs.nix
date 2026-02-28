{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "clean-dev-dirs";
    version = "2.7.0";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-ygLDRcu64KYmX3eJqSMWYf7Y5RjSXxeLxWX+eDCoVME=";
    };

    cargoHash = "sha256-qEBZyMbU/xbPmY5Yteiq+l3a+mDHtwo8kz1ZLEB+H+Q=";
    doCheck = false;

    meta = {
      description = "A fast and efficient CLI tool for recursively cleaning Rust target/ and Node.js node_modules/ directories to reclaim disk space";
      homepage = "https://github.com/TomPlanche/clean-dev-dirs";
      license = with lib.licenses; [asl20 mit];
      mainProgram = pname;
    };
  }
