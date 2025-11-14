{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nix-package-updater";
    version = "0.4.0";

    src = fetchFromGitHub {
      owner = "dsully";
      repo = pname;
      rev = "00de9e63ec5be567435623576be0e99081084ea0";
      hash = "sha256-TINomVPpB+lesbJxQ+z6xxzkzUhuKNFyc1/dJcvCif0=";
    };

    cargoHash = "sha256-NjTfVP+dEMws3I8ZgiALP54XKR7ruVifpCMBsNpA4y0=";

    nativeBuildInputs = [
      pkg-config
    ];

    buildInputs = [
      libgit2
      openssl
      zlib
    ];

    meta = {
      description = "Update Nix Packages";
      homepage = "https://github.com/dsully/nix-package-updater";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
