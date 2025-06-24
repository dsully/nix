{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "pyrefly";
    version = "0.20.0";

    env.RUSTC_BOOTSTRAP = 1;

    src = fetchFromGitHub {
      owner = "facebook";
      repo = "pyrefly";
      rev = "affebbea85d42e41f923464c7ddaeba531ad8acf";
      hash = "sha256-h7eAt1kZOkbmbZlfAk0XaR0bnci0Iq6ph1bjx6HnrIE=";
    };

    cargoHash = "sha256-0MMWz2PxQJp6P0Kn0zer1qckZOA+i7DhIK6JBgfo3Lg=";

    doCheck = false;
    useFetchCargoVendor = true;

    meta = {
      description = "A fast type checker and IDE for Python";
      homepage = "https://github.com/facebook/pyrefly";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
