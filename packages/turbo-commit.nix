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
      description = "Turbocommit is a Rust-based CLI tool that generates high-quality git commit messages in accordance with the Conventional Commits specification, using OpenAI API compatible service. It is easy to use and a cost-effective way to keep git commit history at a higher quality, helping developers stay on track with their work";
      homepage = "https://github.com/dikkadev/turboCommit";
      license = lib.licenses.mit;
      mainProgram = "turbo-commit";
    };
  }
