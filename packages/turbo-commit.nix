{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "turbo-commit";
    version = "e94cf45f";

    src = fetchFromGitHub {
      owner = "dikkadev";
      repo = "turboCommit";
      rev = "e94cf45fff05fc805d1fd1d1d0f2512336b357c7";
      hash = "sha256-jvu4FDRW4cYlIcr8mR6aj4cPBQQIMnAwsrtIgzNJqpA=";
    };

    cargoHash = "sha256-nfyEZo/wXf6wK5slIvNpNDUL7OqzEgeCY3eXdGyiHoQ=";
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
