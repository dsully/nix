{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "timecop";
    version = "0.1.11";

    src = fetchFromGitHub {
      owner = "kamilmac";
      repo = "timecop";
      rev = "e3f24275fdd9c0e942fbfe62a0d26154fc8b2bab";
      hash = "sha256-ssQl2Z7tp4zOrALoyu7vX7e795quTLuxRCVbfGqiD8U=";
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
