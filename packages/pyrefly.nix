{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "pyrefly";
    version = "0.21.0";

    env.RUSTC_BOOTSTRAP = 1;

    src = fetchFromGitHub {
      owner = "facebook";
      repo = pname;
      rev = "bd52a9d93125b6c0d3d4722ea8fe81ebbdde6402";
      hash = "sha256-OCop/w8Tp0qP0DjM352T+C8Uh16vKjc8JtM8qMv4kb4=";
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
