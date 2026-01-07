{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nurl";
    rev = "7eda9594876d79339b0792c50a2cde7da8b320a7";
    version = "0.3.13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nurl";
      hash = "sha256-4SHyTndTo2PfiSA4zgHTUaTivFreah53XE4p1cVYTQQ=";
    };

    cargoHash = "sha256-CbEGKjZXfrtVbhFEZ9ewTyLB9msDtdjJwJam7fQ3RGA=";
    doCheck = false;

    meta = {
      description = "Generate Nix fetcher calls from repository URLs [maintainer=@figsoda";
      homepage = "https://github.com/nix-community/nurl";
      changelog = "https://github.com/nix-community/nurl/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mpl20;
      mainProgram = pname;
    };
  }
