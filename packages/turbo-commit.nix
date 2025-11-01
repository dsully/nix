{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "turbo-commit";
    version = "2.1.0";

    src = fetchFromGitHub {
      owner = "dikkadev";
      repo = "turboCommit";
      rev = "706102bd04f410a2fdbf8d5dcff5718dfe2ff02d";
      hash = "sha256-cKwq4fxC9hJ0/FFDGfK08fHYZxpWFdA6GwSdwufLP1M=";
    };

    cargoHash = "sha256-SdBYZbyahiJrKufTje/zXe8MCSDHHURQNXnpljqLSVw=";
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
