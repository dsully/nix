{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "qbit-tools";
    version = "0.3.8";

    src = fetchFromGitHub {
      owner = "dsully";
      repo = "qbit-tools";
      rev = "8e7cd2191d8577c25ad47a90ad4ccd94ce6f07e9";
      hash = "sha256-d0H/kcJ7n9QL3GDW9HMxA1aNMbp7K/sVwPvGp3FcL+I=";
    };

    cargoHash = "sha256-xux2ciJKntJW31SNB7Kg9aMTnNx+1IP1hl8lIoa8fDY=";
    doCheck = false;

    nativeBuildInputs = lib.optionals stdenv.isLinux [
      pkg-config
    ];

    buildInputs = lib.optionals stdenv.isLinux [
      openssl
    ];

    meta = {
      description = "QB Tools";
      homepage = "https://github.com/dsully/qbit-tools.git";
      mainProgram = "qbit-status";
    };
  }
