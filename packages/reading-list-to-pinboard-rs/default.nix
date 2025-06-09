{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "reading-list-to-pinboard-rs";
    version = "unstable-2025-02-05";

    src = fetchFromGitHub {
      owner = "schwa";
      repo = "reading-list-to-pinboard-rs";
      rev = "1c15b962baef8311a46181ebcfd6d2cf5abc38e3";
      hash = "sha256-3dqB5B2Onp+hXbiQcNSKb1BRlDCSStR8EZpmph95Shg=";
    };

    cargoLock = {
      lockFile = ./Cargo.lock;
    };

    postPatch = ''
      ln -s ${./Cargo.lock} Cargo.lock
    '';

    nativeBuildInputs = [
      pkg-config
    ];

    buildInputs = [
      openssl
    ];

    meta = {
      description = "A simple rust project to upload Safari Reading List links to pinboard or raindrop";
      homepage = "https://github.com/schwa/reading-list-to-pinboard-rs";
      license = lib.licenses.mit;
      mainProgram = "reading-list-to-pinboard-rs";
    };
  }
