{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "feluda";
    rev = "1e841a37b33f1c78ab4f2d22e7203ac2d081e8df";
    version = "1.9.8-rc1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "anistark";
      repo = pname;
      hash = "sha256-sGqi1yGn2JcgZ/nDjCTbbK5A3T3pAj7PE0f6KlEh5dM=";
    };

    cargoHash = "sha256-HoLqbogtlTkvc8KzlY8Ha/8wYIAIhdze7lgECBcEk2U=";
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
