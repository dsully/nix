{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "prmt";
    rev = "c0ac77562b4d44023e04534d8e521c998356e18a";
    version = "0.1.7-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "3axap4eHko";
      repo = "prmt";
      hash = "sha256-S2avJH49BJF2A7FiPSVX6S2ZU7vpSMGuG8oVD3c+6jQ=";
    };

    cargoHash = "sha256-5UoT8SVfgK34YKPL9bZ47GPPmerAbOXXtc84uiyPP6Y=";
    doCheck = false;

    meta = {
      description = "Ultra-fast, customizable shell prompt generator";
      homepage = "https://github.com/3axap4eHko/prmt";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
