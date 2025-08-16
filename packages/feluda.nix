{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "feluda";
    rev = "c86a4ffc447f916c89d62c6e27bf7d22e0bc66cb";
    version = "1.9.8-rc1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "anistark";
      repo = pname;
      hash = "sha256-I23eRMkrzzHP06RGloR+o8bi7FwvKDlXjpSoxst312M=";
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
