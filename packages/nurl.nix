{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nurl";
    rev = "d064e62e59d6403d8dc4cb4f2d382efce9be4419";
    version = "0.3.13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nurl";
      hash = "sha256-q8bK6qzWOAg8mUG8oPyZis2OiLdvDLpy7cEvz4SfZ/Y=";
    };

    cargoHash = "sha256-UhMCR4/thsQ8vYAcXrNhi9tj2y+FidQqEfok2KnF+Z8=";
    doCheck = false;

    meta = {
      description = "Generate Nix fetcher calls from repository URLs [maintainer=@figsoda";
      homepage = "https://github.com/nix-community/nurl";
      changelog = "https://github.com/nix-community/nurl/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mpl20;
      mainProgram = pname;
    };
  }
