{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "feluda";
    version = "1.9.8";

    src = fetchFromGitHub {
      owner = "anistark";
      repo = pname;
      rev = "e44ef7553ae065e3154f6e99c079083922bae881";
      hash = "sha256-doWvvfkls5qKYR8EAv7tEFv+dXVF21A0b102baQI7yQ=";
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
