{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nh";
    rev = "ec31d400f7c8efde85ab4fd5913845713c869efc";
    version = "4.3.0-beta1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nh";
      hash = "sha256-Iwesk5vXbgGMJQiUn6qFRSu9ktgMIMY2IgC3GFQ5IoI=";
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
