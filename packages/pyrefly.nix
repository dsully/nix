{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "pyrefly";
    version = "0.20.0";

    env.RUSTC_BOOTSTRAP = 1;

    src = fetchFromGitHub {
      owner = "facebook";
      repo = "pyrefly";
      rev = "005de4d51b70046221680344a769c983405129e6";
      hash = "sha256-pHipReYWrhr0MJzZd7pkGCO8K0+0xpMMdvVXrQbJq4w=";
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
