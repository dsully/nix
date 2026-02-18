{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nh";
    rev = "c274db89da4aba54f4760f6e3e02874890456102";
    version = "4.3.0-beta1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nh";
      hash = "sha256-BHj6oF22W1ghDD3JgUb/Abj7qPENd+UrWFrGMKhvwuw=";
    };

    cargoHash = "sha256-JeKTrA9AbAyjZ54rZqN66HexxvNFSWEsaFM4nvVK4c4=";
    doCheck = false;

    meta = {
      description = "Yet another Nix CLI helper. [Maintainers=@NotAShelf";
      homepage = "https://github.com/nix-community/nh";
      changelog = "https://github.com/nix-community/nh/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.eupl12;
      mainProgram = pname;
    };
  }
