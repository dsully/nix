{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "clean-dev-dirs";
    version = "2.4.1";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-4TXNzNwOT2xw8ZpN9fjyn0/npvNFa+MghNp/d3EpJPY=";
    };

    cargoHash = "sha256-+lTXvTJ4PUVQL+6/62imJOc2BicVxeX9mDCfSKoP8Jw=";
    doCheck = false;

    meta = {
      description = "A fast and efficient CLI tool for recursively cleaning Rust target/ and Node.js node_modules/ directories to reclaim disk space";
      homepage = "https://github.com/TomPlanche/clean-dev-dirs";
      license = with lib.licenses; [asl20 mit];
      mainProgram = pname;
    };
  }
