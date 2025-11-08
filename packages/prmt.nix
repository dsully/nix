{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "prmt";
    rev = "8ef24b27c4109592b389023258ff4e2cbfbdef7f";
    version = "0.1.7";

    src = fetchFromGitHub {
      inherit rev;
      owner = "3axap4eHko";
      repo = "prmt";
      hash = "sha256-CLSBthofkVdNE/ayecTRLtFDxtGesDuEGw1/Jutpu+c=";
    };

    cargoHash = "sha256-0TYjXpR3VyRdI+3ZIPnoaM1Mod0rXOinpByeOduKSdk=";
    doCheck = false;

    meta = {
      description = "Ultra-fast, customizable shell prompt generator";
      homepage = "https://github.com/3axap4eHko/prmt";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
