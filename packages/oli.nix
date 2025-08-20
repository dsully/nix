{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "oli";
    version = "61fb4fb2";

    src = fetchFromGitHub {
      owner = "amrit110";
      repo = pname;
      rev = "61fb4fb20e280a3c7742e2a5ff5cd8bb11e52ac2";
      hash = "sha256-QlLDmed1wg/n96lpjHKq449940OgPspVUqmF1ebglKo=";
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
