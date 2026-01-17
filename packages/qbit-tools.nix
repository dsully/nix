{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "qbit-tools";
    version = "0.3.7";

    src = fetchFromGitHub {
      owner = "dsully";
      repo = "qbit-tools";
      rev = "7b55b6c5773edaf787b733d3b5353149d9e4c839";
      hash = "sha256-rD0LUIiPuVX4d44vhkCS8hggT9+LUOL0QFlsvM9Yc54=";
    };

    cargoHash = "sha256-lkFoU3dSx1cNRTGu2O/ywWUQ+20Ps+jZPligzYjZH40=";
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
