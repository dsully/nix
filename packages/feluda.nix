{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "feluda";
    rev = "f32d72c5868fb496c3f22e46861991dca2acfd5b";
    version = "1.9.8-rc1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "anistark";
      repo = pname;
      hash = "sha256-/NW6Tz7Rlr9wVYWFkYFHKRnu1Tuum3/rC+OXYqrWRwU=";
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
