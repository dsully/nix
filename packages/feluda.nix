{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "feluda";
    rev = "183c2a496738c620448991ba35431abee3e3e3b4";
    version = "1.9.8-rc1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "anistark";
      repo = pname;
      hash = "sha256-4E4F7G1p6P12DQ5jvrMxVRwRiD17qp3JxrB949AMxGI=";
    };

    cargoHash = "sha256-ul8R/zamLXzquslKOrXi/MTC6uTzzah76v4D45yP4Ek=";
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
