{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "oli";
    version = "2025-05-11-30c2af6";

    src = fetchFromGitHub {
      owner = "amrit110";
      repo = "oli";
      rev = "ae34bea73795959c2e26c337ece2cfffe5ec5f5f";
      hash = "sha256-ILjl/y8HBjaN+1dK3x0LZ5jDe4NBW8kHVcp7D+TO6WY=";
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
