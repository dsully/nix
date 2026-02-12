{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nurl";
    rev = "fb9e05efa3f378d82f6e6294f31c1dd53765dd46";
    version = "0.3.13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nurl";
      hash = "sha256-EMBt0a/+a4HOvH3F/0BHI5HCeWY9YBs+h0Pt2gebSzM=";
    };

    cargoHash = "sha256-eSY+bTa8LDYCQPI8MveafwCGpR93MC/MPmTXD7D/oPA=";
    doCheck = false;

    meta = {
      description = "Generate Nix fetcher calls from repository URLs [maintainer=@figsoda";
      homepage = "https://github.com/nix-community/nurl";
      changelog = "https://github.com/nix-community/nurl/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mpl20;
      mainProgram = pname;
    };
  }
