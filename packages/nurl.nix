{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nurl";
    rev = "2f91e07c0a4499851f1d07806cc31114484ee0ee";
    version = "0.3.13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nurl";
      hash = "sha256-1mcy36mvmCvV9FHbg/mOzj24ip6H6VsmJtq5YJGJWq0=";
    };

    cargoHash = "sha256-P3cLzZ9bcTArvxzX3As7Oo3h5Dzxkjbkw2d20EPncJo=";
    doCheck = false;

    meta = {
      description = "Generate Nix fetcher calls from repository URLs [maintainer=@figsoda";
      homepage = "https://github.com/nix-community/nurl";
      changelog = "https://github.com/nix-community/nurl/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mpl20;
      mainProgram = pname;
    };
  }
