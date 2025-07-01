{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "pyrefly";
    version = "0.21.0";

    env.RUSTC_BOOTSTRAP = 1;

    src = fetchFromGitHub {
      owner = "facebook";
      repo = pname;
      rev = "db0f6095918cfdfeb937f1bb79d678fb0f78c0d2";
      hash = "sha256-1r3we7twt8BPsi0yuiyh/RBPFTbUsu15Y7quafISt2Y=";
    };

    cargoHash = "sha256-ql66BrQlsTopzfP92+Yosjx6cWmM/9Aikza1YfKlF7U=";
    doCheck = false;
    useFetchCargoVendor = true;

    meta = {
      description = "A fast type checker and IDE for Python";
      homepage = "https://github.com/facebook/pyrefly";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
