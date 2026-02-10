{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "timecop";
    version = "0.1.12";

    src = fetchFromGitHub {
      owner = "kamilmac";
      repo = "timecop";
      rev = "eb3fbd20422ffae787ff71a375578171520c81da";
      hash = "sha256-2mD6nZHZog2q0sf8rYxKaLcbSSHyLB32pm41xwPNiaM=";
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
