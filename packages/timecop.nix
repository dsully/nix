{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "timecop";
    version = "0.1.12";

    src = fetchFromGitHub {
      owner = "kamilmac";
      repo = "timecop";
      rev = "5dfec6ebe17206fb8b8d45f1dbc74aca795d002d";
      hash = "sha256-gBAfV079rHNnlR9O4XXwWO1TQivAFjkdcmn2FoyiPe4=";
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
