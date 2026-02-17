{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "worktrunk";
    version = "0.24.1";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-iOh5TssjMn5nFIJu2SyoCMGoaea+oLKsrSzRHuJw5uk=";
    };

    cargoHash = "sha256-qTUCMkbCg66gBOSkfL2qNLYAs+izimIey9qV2Z0e2wg=";
    doCheck = false;

    meta = {
      description = "";
      homepage = "https://crates.io/crates/worktrunk";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
