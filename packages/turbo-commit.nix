{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "turbo-commit";
    version = "7dfb4e67";

    src = fetchFromGitHub {
      owner = "dikkadev";
      repo = "turboCommit";
      rev = "7dfb4e671e8ca41bb72a35caa108098bbd9a5244";
      hash = "sha256-3GKWZEOCTlqkvE5Xyg6vEQFDGBu0U+IB80uZ+nGgmIA=";
    };

    cargoHash = "sha256-5J8S4R4P7mFAba+fsdoiVbpg9ghkjnzZl7Ax4pjgRi4=";
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
