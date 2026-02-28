{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nh";
    rev = "dd403573ee5ea0aa3de36e2a73ea60b86a478daf";
    version = "4.3.0-beta1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nh";
      hash = "sha256-snob6CYkIMnJLLLb/VTHO/b3Yep493HPBcUBqvBmqYc=";
    };

    cargoHash = "sha256-BLv69rL5L84wNTMiKHbSumFU4jVQqAiI1pS5oNLY9yE=";
    doCheck = false;

    meta = {
      description = "Yet another Nix CLI helper. [Maintainers=@NotAShelf";
      homepage = "https://github.com/nix-community/nh";
      changelog = "https://github.com/nix-community/nh/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.eupl12;
      mainProgram = pname;
    };
  }
