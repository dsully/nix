{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "feluda";
    version = "1.9.8-rc1";

    src = fetchFromGitHub {
      owner = "anistark";
      repo = pname;
      rev = "af4c7cb20b398c9dfc60d9fc0475f7872638315c";
      hash = "sha256-jGZ9QMxzHdW3iLVV+R/a9x5Tpruutcmutvw8nZW4xNQ=";
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
