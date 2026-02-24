{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nh";
    rev = "2b9d0324b814a1b9e8eb4f5437209475d8e0b047";
    version = "4.3.0-beta1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nh";
      hash = "sha256-mJsk4hvQBjoCjSxOqeB0FW9zRrh+k/N72uUXouNyRq0=";
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
