{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "turbo-commit";
    version = "4ffc3dd7";

    src = fetchFromGitHub {
      owner = "dikkadev";
      repo = "turboCommit";
      rev = "4ffc3dd74c25ccfafe1b4a8a60e9f97be37d4b01";
      hash = "sha256-7SU0lKX2LkjBE+RjW4F7cVfV2gT3TaavqHC8KQ9M2VU=";
    };

    cargoHash = "sha256-0jYPfaFrvrAAfulRoi4GOypvOw9i0ZGJi8UhLnY0jrQ=";
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
