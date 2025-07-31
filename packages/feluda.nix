{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "feluda";
    version = "1.9.8";

    src = fetchFromGitHub {
      owner = "anistark";
      repo = pname;
      rev = "7b401b8715ecfab5d54a36784d633f30691f8f8b";
      hash = "sha256-JPTImXtpn1QIEOBRkLp/zm7ODp0ce3IQqL5VZiG5BU4=";
    };

    cargoHash = "sha256-E9ggOC3J6lMeY2PXZLmfxIhunTdPwbphikImWc0XpZg=";
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
