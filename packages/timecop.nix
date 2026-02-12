{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "timecop";
    version = "0.1.12";

    src = fetchFromGitHub {
      owner = "kamilmac";
      repo = "timecop";
      rev = "d1399e2cf3ac5e8c8bef5f41b97df792f67e0329";
      hash = "sha256-tZh7qLAPPnUGzD4aJ2sdrNAd2DQhoFNk4+9KIn3r0r8=";
    };

    cargoHash = "sha256-kY3sNLlLqqgFsfngAaLEev1b0GPCAPU/mGkCTyUMu8A=";
    doCheck = false;

    nativeBuildInputs = [
      pkg-config
    ];

    buildInputs = [
      libgit2
      openssl
      zlib
    ];

    env = {
      OPENSSL_NO_VENDOR = true;
    };

    meta = {
      description = "";
      homepage = "https://github.com/kamilmac/timecop";
      mainProgram = pname;
    };
  }
