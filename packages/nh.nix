{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nh";
    rev = "8c5e29cdc321714d518c7d0c057b8d912c30448e";
    version = "4.3.0-beta1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nh";
      hash = "sha256-aLWuo5CR5Mw20krNR0/JhZ1fC35PgJFAVWwtqIkkJAk=";
    };

    cargoHash = "sha256-1ewOocVkr/uTow3rymzsDKwEYGxg3s9uBrZm6hwUQLg=";
    doCheck = false;

    meta = {
      description = "Yet another Nix CLI helper. [Maintainers=@NotAShelf";
      homepage = "https://github.com/nix-community/nh";
      changelog = "https://github.com/nix-community/nh/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.eupl12;
      mainProgram = pname;
    };
  }
