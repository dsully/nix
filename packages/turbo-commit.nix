{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "turbo-commit";
    version = "1.5.4";

    src = fetchFromGitHub {
      owner = "dikkadev";
      repo = "turboCommit";
      rev = "b7be8d681e42813ff2082d4ccb79ed5805937dbb";
      hash = "sha256-0Ftox8jViWCSf/2l8jvc9p4rQab1yDnISCwfM7Hhnb8=";
    };

    cargoHash = "sha256-JhVISTqeNixz2SECcwQ+HW+LGS9Mpc0GUGSEYH9ECnQ=";
    useFetchCargoVendor = true;
    doCheck = false;

    nativeBuildInputs = [
      pkg-config
    ];

    buildInputs = [
      libgit2
      openssl
      zlib
    ];

    meta = {
      description = "Turbocommit is a tool that generates high-quality git commit messages in accordance with the Conventional Commits specification";
      homepage = "https://github.com/dikkadev/turboCommit";
      license = lib.licenses.mit;
      mainProgram = "turbocommit";
    };
  }
