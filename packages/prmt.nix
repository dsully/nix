{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "prmt";
    rev = "b86edbbca9094f45f3f4f5466a92574b3939d417";
    version = "0.1.7-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "3axap4eHko";
      repo = "prmt";
      hash = "sha256-NfnVWkGVewky6s49RfM0pFyHFypaAZfjIdEDIus36mg=";
    };

    cargoHash = "sha256-Vc2uCFD3A3huSFaYbgZHRWgiQnxXkz7BzvmdT7AsnoY=";
    doCheck = false;

    meta = {
      description = "Ultra-fast, customizable shell prompt generator";
      homepage = "https://github.com/3axap4eHko/prmt";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
