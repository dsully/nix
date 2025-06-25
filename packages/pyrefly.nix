{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "pyrefly";
    version = "0.20.0";

    env.RUSTC_BOOTSTRAP = 1;

    src = fetchFromGitHub {
      owner = "facebook";
      repo = "pyrefly";
      rev = "71a577153c463ea95fb967a9aa963a4ef25101a6";
      hash = "sha256-WZy9BJdfjNck3LVm5I0FgS7G/Y+UvHJF3EMu5pJEmXc=";
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
