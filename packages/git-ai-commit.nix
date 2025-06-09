{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "git-ai-commit";
    version = "0.1.1";

    src = fetchFromGitHub {
      owner = "ince01";
      repo = "git-ai-commit";
      rev = "8a46e9065fb4ee0fa131d465c5db8957c9d184e5";
      hash = "sha256-BNNPaDSLRwhz1jJMck08inj0YdwOex7T3ccxGQZMGJg=";
    };

    cargoHash = "sha256-LwZnBCglMVOhaZ7kslsnZEFZAXJWoGreD64OmLfTgBM=";
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
      description = "Smarter commits, crafted by AI & powered by Rust’s speed";
      homepage = "https://github.com/ince01/git-ai-commit";
      mainProgram = "git-ai-commit";
    };
  }
