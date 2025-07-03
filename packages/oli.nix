{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "oli";
    version = "0.1.4-post1";

    src = fetchFromGitHub {
      owner = "amrit110";
      repo = pname;
      rev = "559a71f026fe31b51aa9d041a0e9814fea96e182";
      hash = "sha256-Kp9wnRN2Of18yAx1tVBt8tG6VaCZPKPisQVAuxgtAco=";
    };

    cargoHash = "sha256-KHTaMG9k5G4Fh9gindqGBZ0J2wRNCaGet2NXNTV01IE=";
    useFetchCargoVendor = true;
    doCheck = false;

    nativeBuildInputs = [
      pkgs.pkg-config
    ];

    buildInputs = [
      pkgs.openssl
    ];

    meta = {
      description = "A simple, fast terminal based AI coding assistant";
      homepage = "https://github.com/amrit110/oli";
      license = lib.licenses.asl20;
      mainProgram = pname;
    };
  }
