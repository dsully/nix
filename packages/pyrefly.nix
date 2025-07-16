{pkgs, ...}:
with pkgs; let
  pkgsWithRust = pkgs.extend (import (builtins.fetchTarball {
    url = "https://github.com/oxalica/rust-overlay/archive/master.tar.gz";
    sha256 = "sha256-Bj7ozT1+5P7NmvDcuAXJvj56txcXuAhk3Vd9FdWFQzk=";
  }));
in
  rustPlatform.buildRustPackage rec {
    rev = "87425452cb03e79e8ca1bed0bc0316fa1cd59b96";
    pname = "pyrefly";
    version = "0.24.0-${rev}";

    nativeBuildInputs = [pkgsWithRust.rust-bin.nightly.latest.minimal];

    src = fetchFromGitHub {
      inherit rev;
      owner = "facebook";
      repo = pname;
      hash = "sha256-5DG3XdZL2NMHxaJUZdwrCm+P8UUKE5Xs2WSHi2IKifg=";
    };

    cargoHash = "sha256-fMEJh/90fLp03gRvZwvy1POjQkrR0tneKfBgc5OMLxI=";
    doCheck = false;
    useFetchCargoVendor = true;

    meta = {
      description = "A fast type checker and IDE for Python";
      homepage = "https://github.com/facebook/pyrefly";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
