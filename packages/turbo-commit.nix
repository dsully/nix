{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "turbo-commit";
    rev = "dd74da0639a2944c0c8b3bfebfcce5d68c308812";
    version = "3.0.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "dikkadev";
      repo = "turboCommit";
      hash = "sha256-EFRUCXZCvZWMVQRCes+f06Cl3cEgrwRY8bjS9u/Mtqw=";
    };

    cargoHash = "sha256-jdOI/1Hln+dVXDM3eNd2UlqJAYqwWag2ZBcZm9g0Z1E=";
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
