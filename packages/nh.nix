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
      hash = "sha256-DvonqSRDrGDZmsRCCBegFWtGvb+7SktKn5Rzxgngw+4=";
    };

    cargoHash = "sha256-cQlOOZwqaKae16EWOykftioNVn5zwCAG6fwX+Bg/8rA=";
    doCheck = false;

    meta = {
      description = "Yet another Nix CLI helper. [Maintainers=@NotAShelf";
      homepage = "https://github.com/nix-community/nh";
      changelog = "https://github.com/nix-community/nh/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.eupl12;
      mainProgram = pname;
    };
  }
