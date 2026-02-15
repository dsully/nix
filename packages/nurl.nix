{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nurl";
    rev = "62fc9c1ca330ba34785c0e603b6a2607f2fd087e";
    version = "0.3.13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nurl";
      hash = "sha256-/HLhOSx9N1Cy6hIeXOn6BfbIlD6Y+AaET+DEmtzEcq0=";
    };

    cargoHash = "sha256-J1U3+1dnyBgPdPYd465MoHdZusyk3ofE29ReiaYeBqo=";
    doCheck = false;

    meta = {
      description = "Generate Nix fetcher calls from repository URLs [maintainer=@figsoda";
      homepage = "https://github.com/nix-community/nurl";
      changelog = "https://github.com/nix-community/nurl/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mpl20;
      mainProgram = pname;
    };
  }
