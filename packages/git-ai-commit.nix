{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "git-ai-commit";
    version = "060b5c3d";

    src = fetchFromGitHub {
      owner = "ince01";
      repo = pname;
      rev = "060b5c3dfbd22ff52d189d6bcf9f4b5e83c00dbe";
      hash = "sha256-ERe2EW9ps1xAR4IKy426jxYEY25ZutfA1k3u0K+b/Ps=";
    };

    cargoHash = "sha256-XjrC/3uvsRKvIvJo7wnZTWJt+zy52QhtFGlHrIoSU9I=";
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
      description = "Smarter commits, crafted by AI & powered by Rust’s speed";
      homepage = "https://github.com/ince01/git-ai-commit";
      mainProgram = pname;
    };
  }
