{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "feluda";
    version = "1.7.0";

    src = fetchFromGitHub {
      owner = "anistark";
      repo = "feluda";
      rev = "e14f0d46b01089e040325c06268b9d9b79edf716";
      hash = "sha256-hQbVX6j2gk0E/PPVW3gWfsLyDpd0AZNJtUcLZ7XtnuI=";
    };

    useFetchCargoVendor = true;
    cargoHash = "sha256-MwfdP7Lbu2PK7KuzPAEuCMFvQM1rNKOAcvJ3HmoM07A=";
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
      mainProgram = "feluda";
    };
  }
