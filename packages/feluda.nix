{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "feluda";
    rev = "c4fc7bf8c3058a004bb9cf59ace26efd05d6234d";
    version = "1.9.8-rc1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "anistark";
      repo = pname;
      hash = "sha256-cmz9qBcB6HRwmq7EHA6/3WBSnPX3fTgAMwh1YshW9Zc=";
    };

    cargoHash = "sha256-WDYW4atvqB9frUlCVooQoeHkoak7954N0iyVapgdjpk=";
    doCheck = false;

    nativeBuildInputs = [
      perl
      pkg-config
    ];

    meta = {
      description = "Detect license usage restrictions in your project";
      homepage = "https://github.com/anistark/feluda";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
