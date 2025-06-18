{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "magic-opener";
    version = "0.2.0";

    src = fetchFromGitHub {
      owner = "dsully";
      repo = "magic-opener";
      rev = "10efd2766047af0dcea2d27f426ddcd4923bd72d";
      hash = "sha256-AdmixBc4WCfjJmc2m2noaNirwEsAte6CexGDY/7ajhw=";
    };

    cargoHash = "sha256-OjZ4ruYtViim8dx20y+0qH8InDjVC4QxtFI3+Qiwjj8=";
    useFetchCargoVendor = true;

    meta = {
      description = "A tool for opening the right thing in the right place";
      homepage = "https://github.com/dsully/magic-opener";
      license = lib.licenses.mit;
      mainProgram = "open";
    };
  }
