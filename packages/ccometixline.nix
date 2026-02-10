{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "ccometixline";
    version = "1.1.1";
    rev = "71f7b81a93878f4b1a36f391fda501d709a84d71";

    src = fetchFromGitHub {
      inherit rev;
      owner = "Haleclipse";
      repo = "CCometixLine";
      hash = "sha256-7V+cTvUkGvS0bDfQfzPOOnuRs63eM+Lm1Q9qsxoQUro=";
    };

    cargoHash = "sha256-Sxsqh2/BbInFcCIoy0UFUYtWO8XVIbW58As3uJ/1z+w=";
    doCheck = false;

    # buildInputs = lib.optionals stdenv.isDarwin [
    #   darwin.apple_sdk.frameworks.Security
    # ];

    meta = {
      description = "Claude Code statusline tool written in Rust";
      homepage = "https://github.com/Haleclipse/CCometixLine";
      changelog = "https://github.com/Haleclipse/CCometixLine/blob/${src.rev}/CHANGELOG.md";
      mainProgram = pname;
    };
  }
