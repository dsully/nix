{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "turbo-commit";
    version = "cc762126";

    src = fetchFromGitHub {
      owner = "dikkadev";
      repo = "turboCommit";
      rev = "cc7621269a8aa0ef0af18c99e1541859fd0ca256";
      hash = "sha256-PSSi+h4KoUxHKSuKZkjvH14k8DaWpAVyUJ+jqoDwC3g=";
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
