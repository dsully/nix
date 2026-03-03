{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nurl";
    rev = "e2591e8c23fdba9911f774423241421ae1535cfe";
    version = "0.3.13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nurl";
      hash = "sha256-shkUKDNmzbp1plFTOJJ8t2fr2vaaMzwS7rdZWcLm0M8=";
    };

    cargoHash = "sha256-fcRqjNeiQeM5PqeV0yyZgmYj9GQj9vpX3wR9zXIRI7Y=";
    doCheck = false;

    meta = {
      description = "Generate Nix fetcher calls from repository URLs [maintainer=@figsoda";
      homepage = "https://github.com/nix-community/nurl";
      changelog = "https://github.com/nix-community/nurl/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mpl20;
      mainProgram = pname;
    };
  }
