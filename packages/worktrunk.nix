{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.15.3";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-3xfxXpGg8o0usxhUCx6PzenovbGFI3WJVVJ5gT3knpU=";
    };

    cargoHash = "sha256-nzoduc5EwPMQPeikSzJ8O0ng5S2iKjInjY6MRcDThXY=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
