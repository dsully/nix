{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "prmt";
    rev = "3f57d82f78c934d27ecfe90b08b115773cd27d7d";
    version = "0.1.7-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "3axap4eHko";
      repo = "prmt";
      hash = "sha256-XQazhPdBosQEPn5yvHdLh4ux6I8xjtM2Xtm7wBMQGss=";
    };

    cargoHash = "sha256-QXDBZjBjNXZVvL83x9b5oNfwgBnkyYCb+e4HKGu2/g0=";
    doCheck = false;

    meta = {
      description = "Ultra-fast, customizable shell prompt generator";
      homepage = "https://github.com/3axap4eHko/prmt";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
