{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "feluda";
    rev = "8a44fad87dcad3c6f24d0bcd4422a90f62da6519";
    version = "1.9.8-rc1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "anistark";
      repo = pname;
      hash = "sha256-ei1Xqvbk2hGP5mUsZyutO4dEX5Id6tOv6CvPIye6+6w=";
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
