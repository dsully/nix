{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "pyrefly";
    version = "0.20.0";

    env.RUSTC_BOOTSTRAP = 1;

    src = fetchFromGitHub {
      owner = "facebook";
      repo = "pyrefly";
      rev = "231ac8d432416208ff10faf5d67ce57f935710f8";
      hash = "sha256-7AiR1lM5HFYJMFNMxCD1//oOms5Laoxx6xXroeyuFkw=";
    };

    cargoHash = "sha256-kmsRwcmXrBISTWIvGX+zOYPZp27N3yo4IrA9dd/19iE=";

    doCheck = false;
    useFetchCargoVendor = true;

    meta = {
      description = "A fast type checker and IDE for Python";
      homepage = "https://github.com/facebook/pyrefly";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
