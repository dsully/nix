{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nix-package-updater";
    version = "0.3.7";

    src = fetchFromGitHub {
      owner = "dsully";
      repo = pname;
      rev = version;
      hash = "sha256-S4ThHjk90UtmCgOHWDU81Rf1A+39cgHSRDgn/AGaA4I=";
    };

    cargoHash = "sha256-lnSBU83VZ2dO1EkOgS1UsypLr4tazy4a+nHGAKAfLxs=";

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
