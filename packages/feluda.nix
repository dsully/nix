{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "feluda";
    version = "1.7.0";

    src = fetchFromGitHub {
      owner = "anistark";
      repo = "feluda";
      rev = "341a07ee34e0bf382de54c6ae573af835c518602";
      hash = "sha256-grb167ol00ywmeULSt2G3qlTcQval4i2uRzUmLRLqWM=";
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
