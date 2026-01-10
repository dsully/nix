{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nurl";
    rev = "c75f82fa104d9e02c34f5f7f054353a0f20f8ce4";
    version = "0.3.13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nurl";
      hash = "sha256-5eQ9U7yyqzSXnx6aqGS+PLq+iRal9XVKG+yhNlTDpvk=";
    };

    cargoHash = "sha256-NAxPhDk/cWhb5mFlBnnBXqn4ql9GO8bBhjfVl83CZV0=";
    doCheck = false;

    meta = {
      description = "Generate Nix fetcher calls from repository URLs [maintainer=@figsoda";
      homepage = "https://github.com/nix-community/nurl";
      changelog = "https://github.com/nix-community/nurl/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mpl20;
      mainProgram = pname;
    };
  }
