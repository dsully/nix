{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nurl";
    rev = "651c1c06fc5ab47fb20486e08efe2423661b038a";
    version = "0.3.13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nurl";
      hash = "sha256-a5NIbJh2mraGbOilI6gvfnnjZMjhu44JiGq3UaYzC9Y=";
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
