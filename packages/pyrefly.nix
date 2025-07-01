{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "pyrefly";
    version = "0.21.0";

    env.RUSTC_BOOTSTRAP = 1;

    src = fetchFromGitHub {
      owner = "facebook";
      repo = pname;
      rev = "fe08893549edd24a42562bbcc996ffbe749a2611";
      hash = "sha256-PQGlCQAsKejSusLzaNXzqgAL+TwUj8MeqZa6ZoF63EM=";
    };

    cargoHash = "sha256-ql66BrQlsTopzfP92+Yosjx6cWmM/9Aikza1YfKlF7U=";
    doCheck = false;
    useFetchCargoVendor = true;

    meta = {
      description = "A fast type checker and IDE for Python";
      homepage = "https://github.com/facebook/pyrefly";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
