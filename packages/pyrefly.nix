{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "pyrefly";
    version = "0.21.0";

    env.RUSTC_BOOTSTRAP = 1;

    src = fetchFromGitHub {
      owner = "facebook";
      repo = pname;
      rev = "c247d452349c10958a44a3842540b12f7634e220";
      hash = "sha256-IcxYoxSMdT8yPUbwSSxMxQvMK+4iShIryfHNhKK4Ft4=";
    };

    cargoHash = "sha256-uIarNrxLz+ila2AgA+WRIgGveBMrwp9Vb710PDCtaa4=";
    doCheck = false;
    useFetchCargoVendor = true;

    meta = {
      description = "A fast type checker and IDE for Python";
      homepage = "https://github.com/facebook/pyrefly";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
