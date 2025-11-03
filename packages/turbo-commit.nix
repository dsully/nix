{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "turbo-commit";
    version = "2.2.1";

    src = fetchFromGitHub {
      owner = "dikkadev";
      repo = "turboCommit";
      rev = "3e9e0b0fd474dce08c411ba12f1c89db3e1e6c74";
      hash = "sha256-+mhuvoKTZAtZvYxogB62ZXM5aOTUkTucc8nCVadTN5E=";
    };

    cargoHash = "sha256-XtNkWkVScVs/KWCDc64srwgx5zI60SYgDawG7edY5Us=";
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
