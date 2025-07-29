{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "oli";
    version = "0.1.4-post1";

    src = fetchFromGitHub {
      owner = "amrit110";
      repo = pname;
      rev = "288c536a71e35b38abd2d938a375538fbf86f3fe";
      hash = "sha256-CGHZ5MzYg+quUw8BbF/GWQStr4mLcLH2EIv7C0ooX2g=";
    };

    cargoHash = "sha256-ZakLeH61PTc9lhvbY4uyhrGfEdtjKAs8l4VWVEw/YX4=";
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
