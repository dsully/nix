{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "timecop";
    version = "0.1.10";

    src = fetchFromGitHub {
      owner = "kamilmac";
      repo = "timecop";
      rev = "651d67fb45aa4b9436e20490f68b2fc2d38edb76";
      hash = "sha256-+mghcFYTEI+rvbWotC2qW1R5FDQ3Swb1ggn4BfGsuvQ=";
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
