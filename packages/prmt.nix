{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "prmt";
    version = "0.2.4";

    src = fetchCrate {
      inherit pname version;
      hash = "sha256-HBfZ8/SkhBm8Vq4aKyp8ypIKu12Jcp6zP2Tg2OU9oyQ=";
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
