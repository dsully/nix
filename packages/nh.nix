{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nh";
    rev = "f4c3b37a4be8cab6c8dbbc977775b232638fc858";
    version = "4.3.0-beta1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nh";
      hash = "sha256-A3bEBKJlWYqsw41g4RaTwSLUWq8Mw/zz4FpMj4Lua+c=";
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
