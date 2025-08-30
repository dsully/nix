{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "feluda";
    rev = "796745037d1b5465d2113c868658496d60da860e";
    version = "1.9.8-rc1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "anistark";
      repo = pname;
      hash = "sha256-TDv6kz0haA8enn8hQ3QByv3Wmq5IJtY6HuOtTlUXSXQ=";
    };

    cargoHash = "sha256-0c4Ws+F9fBJjvX11pFMb7KpfKlVRseBxiH2WTEauA7s=";
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
