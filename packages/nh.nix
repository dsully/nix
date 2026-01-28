{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nh";
    rev = "5a6aea55d9fb880720b84f2f4e58209b1f19ea4a";
    version = "4.3.0-beta1-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nh";
      hash = "sha256-lMT7YLMGgPGeezPd2syj4+Q9NyCbMHfWrt+t34Jcc0M=";
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
