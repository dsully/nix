{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "pyrefly";
    version = "0.21.0";

    env.RUSTC_BOOTSTRAP = 1;

    src = fetchFromGitHub {
      owner = "facebook";
      repo = pname;
      rev = "e18a21af44a51df7303f80d626f7190e164f9181";
      hash = "sha256-OYyqVPcDg34kgf0p85h9kAcmt5xe0DSKi4yaJGHDRVE=";
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
