{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "pyrefly";
    version = "0.21.0";

    env.RUSTC_BOOTSTRAP = 1;

    src = fetchFromGitHub {
      owner = "facebook";
      repo = pname;
      rev = "058c3a721593846c8eb665e697c007934428c4df";
      hash = "sha256-Az+RFte3iwvByrYiFBh0bUIjSspsjmixZrQWvndS244=";
    };

    cargoHash = "sha256-tBtZCX7HLIAmqBxBaHGzxR7Ro2pVk4VYJmElSQqDl+w=";
    doCheck = false;
    useFetchCargoVendor = true;

    meta = {
      description = "A fast type checker and IDE for Python";
      homepage = "https://github.com/facebook/pyrefly";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
