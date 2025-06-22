{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "pyrefly";
    version = "0.20.0";

    env.RUSTC_BOOTSTRAP = 1;

    src = fetchFromGitHub {
      owner = "facebook";
      repo = "pyrefly";
      rev = "39f10ddef76a9d8a135b8ba4ccd688cddd7b001c";
      hash = "sha256-OIG2TMH+/CMXOssWeczXAnbORCsls/AgOtvq3NZq6vY=";
    };

    cargoHash = "sha256-NNnj90N6KGskZgs5xM4Dzmz1h53Cw/53uX5B4npdzKk=";

    doCheck = false;
    useFetchCargoVendor = true;

    meta = {
      description = "A fast type checker and IDE for Python";
      homepage = "https://github.com/facebook/pyrefly";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
