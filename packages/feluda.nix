{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "feluda";
    version = "1.9.2";

    src = fetchFromGitHub {
      owner = "anistark";
      repo = pname;
      rev = "66057dafc8bf03d6e065517cc9c9312385e058d9";
      hash = "sha256-VQVOTtu/CdcZHJWJ7MIla0FZTYGo8adVAqHinJ5bz+Y=";
    };

    useFetchCargoVendor = true;
    cargoHash = "sha256-N3wV39jV4pjVR7Uf+GO737oMuUB9ZC+5r2Pj3j5cwZM=";
    doCheck = false;

    nativeBuildInputs = [
      pkg-config
    ];

    buildInputs = [
      openssl
    ];

    meta = {
      description = "Detect license usage restrictions in your project";
      homepage = "https://github.com/anistark/feluda";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
