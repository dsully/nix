{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "feluda";
    version = "1.7.0";

    src = fetchFromGitHub {
      owner = "anistark";
      repo = "feluda";
      rev = "d5cd951ad9af234d9b6ca6fcadd43f6c50c8c3f0";
      hash = "sha256-cyX5Cyz8NHl3M0uu5dB3E13YF+XIcnt8pjtd4qj+fSk=";
    };

    useFetchCargoVendor = true;
    cargoHash = "sha256-MwfdP7Lbu2PK7KuzPAEuCMFvQM1rNKOAcvJ3HmoM07A=";
    doCheck = false;

    nativeBuildInputs = [
      pkgs.pkg-config
    ];

    buildInputs = [
      pkgs.openssl
    ];

    meta = {
      description = "Detect license usage restrictions in your project";
      homepage = "https://github.com/anistark/feluda";
      license = lib.licenses.mit;
      mainProgram = "feluda";
    };
  }
