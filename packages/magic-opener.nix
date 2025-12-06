{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "magic-opener";
    version = "0.3.2";
    rev = "c95028492b65bbfa7bef8457fbfc75ea5971826d";

    src = fetchFromGitHub {
      inherit rev;
      owner = "dsully";
      repo = pname;
      hash = "sha256-ZESQpTERsxuISop9158S0i9AkyCoB1mV3NLz4/+GQXY=";
    };

    cargoHash = "sha256-uY+oO014QFxB8elTwENJbOQ/BhD9LQcGG9uFBTDT2tE=";

    meta = {
      description = "A tool for opening the right thing in the right place";
      homepage = "https://github.com/dsully/magic-opener";
      license = lib.licenses.mit;
      mainProgram = "open";
    };
  }
