{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "pyrefly";
    version = "0.21.0";

    env.RUSTC_BOOTSTRAP = 1;

    src = fetchFromGitHub {
      owner = "facebook";
      repo = pname;
      rev = "d186028ed276f33dfd3c713d67bf8c52da3d39b7";
      hash = "sha256-8+B4MKAj6VnfVLkeA10JNpsyflDyCHcOMsoxc9jpGCk=";
    };

    cargoHash = "sha256-OQoUUAFS5c3YX27gmWeiHRIwaFpsXI8ibz3LO2cnOys=";
    doCheck = false;
    useFetchCargoVendor = true;

    meta = {
      description = "A fast type checker and IDE for Python";
      homepage = "https://github.com/facebook/pyrefly";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
