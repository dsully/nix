{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nurl";
    rev = "d8835330beeb690b5351459be1adbc46e68debc2";
    version = "0.3.13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nurl";
      hash = "sha256-rVqF+16esE27G7GS55RT91tD4x/GAzfVlIR0AgSknz0=";
    };

    cargoHash = "sha256-OUJGxNqytwz7530ByqkanpseVJJXAea/L2GIHnuSIqk=";
    doCheck = false;

    meta = {
      description = "Generate Nix fetcher calls from repository URLs [maintainer=@figsoda";
      homepage = "https://github.com/nix-community/nurl";
      changelog = "https://github.com/nix-community/nurl/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mpl20;
      mainProgram = pname;
    };
  }
