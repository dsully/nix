{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nurl";
    rev = "977f9711c77e95dff23796c6f7b5fc90cd8b9e8f";
    version = "0.3.13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nurl";
      hash = "sha256-zm+RTE2uIORlCIh1bSpvFkezeUuPY0SBkvjgiKW1s0g=";
    };

    cargoHash = "sha256-IvEwznmtlQ2fNi61uj5M/3KgSSLDRvtjL8Th8Y1kj2c=";
    doCheck = false;

    meta = {
      description = "Generate Nix fetcher calls from repository URLs [maintainer=@figsoda";
      homepage = "https://github.com/nix-community/nurl";
      changelog = "https://github.com/nix-community/nurl/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mpl20;
      mainProgram = pname;
    };
  }
