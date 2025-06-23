{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "oli";
    version = "bb66e7c98b41b093780033797f0eba33fb71584c";

    src = fetchFromGitHub {
      owner = "amrit110";
      repo = "oli";
      rev = version;
      hash = "sha256-kri00m4T78TcfNbdajqyPLsxAZx5bqJMRwnsuEjmzEs=";
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
      mainProgram = "oli";
    };
  }
