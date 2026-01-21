{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nurl";
    rev = "4dc225f1c8f2ed25ccdf96997e131a530a9370a6";
    version = "0.3.13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nurl";
      hash = "sha256-HehylffsMv6PYhQoL2U41WyeJyufKuobg+NbYVsw4i0=";
    };

    cargoHash = "sha256-06AB5/aKMACGLkbs3Rod9BnJedKKDxWuYWZCJNdybH4=";
    doCheck = false;

    meta = {
      description = "Generate Nix fetcher calls from repository URLs [maintainer=@figsoda";
      homepage = "https://github.com/nix-community/nurl";
      changelog = "https://github.com/nix-community/nurl/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mpl20;
      mainProgram = pname;
    };
  }
