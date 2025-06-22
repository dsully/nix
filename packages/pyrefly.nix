{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "pyrefly";
    version = "0.20.0";

    env.RUSTC_BOOTSTRAP = 1;

    src = fetchFromGitHub {
      owner = "facebook";
      repo = "pyrefly";
      rev = "5baea66d94edffdd85458fafa8a34996854681a2";
      hash = "sha256-ZlNreo/6zfkdP9+vt/2dM/4pLH7tjnbV4L3ApP1GxhQ=";
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
