{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nurl";
    rev = "c82c70226166bff564190abc1672eda62589d819";
    version = "0.3.13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nurl";
      hash = "sha256-cdZm33Pnum6bjicFO7hPXnziKPIZ6R8qzO5HKGnBo40=";
    };

    cargoHash = "sha256-Rr6vl1AKLFdD6GY1n8DsJ9TMsQRBbIpkS2orp7GZrzI=";
    doCheck = false;

    meta = {
      description = "Generate Nix fetcher calls from repository URLs [maintainer=@figsoda";
      homepage = "https://github.com/nix-community/nurl";
      changelog = "https://github.com/nix-community/nurl/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mpl20;
      mainProgram = pname;
    };
  }
