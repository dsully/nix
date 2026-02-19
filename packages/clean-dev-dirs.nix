{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "clean-dev-dirs";
    version = "2.5.1";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-Kd9pUFwX0foCEaI83x3SLtLaL58qyXnDl4qTXT5wseQ=";
    };

    cargoHash = "sha256-/xvHuZWQV3Sgvsu04TLTLmQvA0PtDM0MXS86eG13ouk=";
    doCheck = false;

    meta = {
      description = "A fast and efficient CLI tool for recursively cleaning Rust target/ and Node.js node_modules/ directories to reclaim disk space";
      homepage = "https://github.com/TomPlanche/clean-dev-dirs";
      license = with lib.licenses; [asl20 mit];
      mainProgram = pname;
    };
  }
