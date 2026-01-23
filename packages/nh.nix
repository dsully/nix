{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nh";
    rev = "f3ada037c14f92cb7a56f18768e6d80219c2431f";
    version = "4.3.0-beta1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nh";
      hash = "sha256-ICMH2e+ZQqN+VA8Jf5haxWevwkjBlbppTmuMEN3d4eY=";
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
