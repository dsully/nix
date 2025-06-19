{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "feluda";
    version = "1.7.0";

    src = fetchFromGitHub {
      owner = "anistark";
      repo = "feluda";
      rev = "29f9c55fc1384e2c849b87879945729deb97fb54";
      hash = "sha256-oelecufRWfswIYr32bXMa9utMPiSqGs4pWfw0W18X7I=";
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
