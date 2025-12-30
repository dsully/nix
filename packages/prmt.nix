{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "prmt";
    rev = "8584ea90594d4c3d5e26198b9604503ad2b3e0a9";
    version = "0.1.7-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "3axap4eHko";
      repo = "prmt";
      hash = "sha256-n5Tq6fnImE744/QaQzkqrRsqk76YNrQUp8/cOEly06I=";
    };

    cargoHash = "sha256-6meuA7D5JoSvG9aAGy+rglt66qckvJBn0FhmYFAiTdA=";
    doCheck = false;

    meta = {
      description = "Ultra-fast, customizable shell prompt generator";
      homepage = "https://github.com/3axap4eHko/prmt";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
