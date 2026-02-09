{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nh";
    rev = "67d936f3bfd170964f90ef18504dc1dc2eeb0ca3";
    version = "4.3.0-beta1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nh";
      hash = "sha256-BcZ92wQwK69iApln/1urAcltkoAJ1mWBt7Lz3i3qvDw=";
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
