{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nurl";
    rev = "6a27dc2cb66e85374d3310563ef5099077a3c952";
    version = "0.3.13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nurl";
      hash = "sha256-U/oIN5B2FKwMoHDdyLJpE2uxJd6pcJEgybVgL0CRb2M=";
    };

    cargoHash = "sha256-nrJSHNdc9UVjyw2uyzD/qXDG1B25anr7m9UO6o37DgY=";
    doCheck = false;

    meta = {
      description = "Generate Nix fetcher calls from repository URLs [maintainer=@figsoda";
      homepage = "https://github.com/nix-community/nurl";
      changelog = "https://github.com/nix-community/nurl/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mpl20;
      mainProgram = pname;
    };
  }
