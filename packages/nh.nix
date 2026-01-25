{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nh";
    rev = "2929047421fc0cbc31c45fab001c5e1bf3e837fd";
    version = "4.3.0-beta1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nh";
      hash = "sha256-gCpkjnputz5etOnUob73hciZ8OXAQ8/FecXzF2P8k4Q=";
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
