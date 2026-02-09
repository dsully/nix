{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "timecop";
    version = "0.1.10";

    src = fetchFromGitHub {
      owner = "kamilmac";
      repo = "timecop";
      rev = "651d67fb45aa4b9436e20490f68b2fc2d38edb76";
      hash = "sha256-R7e4X9JLNUqg+CvSKB+Xcf37nvKdPZbai4KWIjOK9NY=";
    };

    cargoHash = "sha256-HmMk93Gh/WtG+xSA0Qcsm6o6d5ROH8m/kEXeyJIHDq0=";
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
