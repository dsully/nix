{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nh";
    rev = "e0eedfbc5e655b1c03f4466ad827c44e0e4582ee";
    version = "4.3.0-beta1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nh";
      hash = "sha256-IdaBS+aCuEAI2HoGcF5E4mGfHAwiIaUiHopqvx4gq1k=";
    };

    cargoHash = "sha256-FDQZ23plLJ9guZ1x+zaaq4fPBOswNhY8wf0N6KSUVAg=";
    doCheck = false;

    meta = {
      description = "Yet another Nix CLI helper. [Maintainers=@NotAShelf";
      homepage = "https://github.com/nix-community/nh";
      changelog = "https://github.com/nix-community/nh/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.eupl12;
      mainProgram = pname;
    };
  }
