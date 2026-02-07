{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nh";
    rev = "347c71b43705a2efcc6e4ebb94e14894bb5d3147";
    version = "4.3.0-beta1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nh";
      hash = "sha256-sLRCTKKt7FsxR/rKrJp5BN++3p8tfuShzIKLMNTh7DA=";
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
