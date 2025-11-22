{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "leadr";
    version = "2.8.5";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-2NG35xnMquyvbqtWX/lJ9XrQOSdG5JZYqZE+4cOwzMA=";
    };

    cargoHash = "sha256-EgYtwgbYybcMB5YoI3rD6zPK1NKH48aaxOoh+GqDV6o=";
    doCheck = false;

    meta = {
      description = "Shell aliases on steroids";
      homepage = "https://crates.io/crates/leadr";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
