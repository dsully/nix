{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nh";
    rev = "7d5ae0607b197115e68e14dcf780070331ff2aa2";
    version = "4.3.0-beta1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nh";
      hash = "sha256-Os7seaXYWMm+ss+DaaZkyJFed9cBx4efYeAyuBmj5Z4=";
    };

    cargoHash = "sha256-DsDp9qTBGqzNDbyez2D95Lok7hfcmPzU4mtHJLCm0CE=";
    doCheck = false;

    meta = {
      description = "Yet another Nix CLI helper. [Maintainers=@NotAShelf";
      homepage = "https://github.com/nix-community/nh";
      changelog = "https://github.com/nix-community/nh/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.eupl12;
      mainProgram = pname;
    };
  }
