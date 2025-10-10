{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "feluda";
    rev = "ef2299c2e19ab4ef82c2ed9fb52615247eb003ad";
    version = "1.9.8-rc1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "anistark";
      repo = pname;
      hash = "sha256-XiKXI4dqMPasYlZ+YcSZMnBrGGl0c6KxexsDsANyQO0=";
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
