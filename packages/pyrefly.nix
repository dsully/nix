{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    rev = "7c8e5c906028488efc24ec81d2f531b45af61591";
    pname = "pyrefly";
    version = "0.22.0-${rev}";

    env.RUSTC_BOOTSTRAP = 1;

    src = fetchFromGitHub {
      inherit rev;
      owner = "facebook";
      repo = pname;
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
