{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "oli";
    version = "0.1.4-post1";

    src = fetchFromGitHub {
      owner = "amrit110";
      repo = pname;
      rev = "4c8d077bb46980a45c464e07da72c42ca1215c7c";
      hash = "sha256-pwP6RGp/GKBMtgx2XA37KgrTqatw068Cb98vSeKBfBo=";
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
