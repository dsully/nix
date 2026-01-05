{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nh";
    rev = "97eaee12ece18a3833b4509ae44df6ed9e7f1ff6";
    version = "4.2.0-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nh";
      hash = "sha256-BA0U9M5279iigdVrFrf9GnmC3LpXr0nShIuzFd3SBXE=";
    };

    cargoHash = "sha256-V+Udw9u8PRl3fE/ZFO0zVlrtHC+vXHNAp5pt4QbFVKA=";
    doCheck = false;

    meta = {
      description = "Yet another Nix CLI helper. [Maintainers=@NotAShelf";
      homepage = "https://github.com/nix-community/nh";
      changelog = "https://github.com/nix-community/nh/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.eupl12;
      mainProgram = pname;
    };
  }
