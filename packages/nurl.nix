{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nurl";
    rev = "41939f5df0937010e73d254396b83f8680aeb2c2";
    version = "0.3.13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nurl";
      hash = "sha256-gVS3RGBW8F/AE8GubthJBw0PquxCHi5sP7O81DEaMVc=";
    };

    cargoHash = "sha256-wEt0LdZHBFKOoXTNtDYEHWtYamlTh1erZ/PbDATL7Hs=";
    doCheck = false;

    meta = {
      description = "Generate Nix fetcher calls from repository URLs [maintainer=@figsoda";
      homepage = "https://github.com/nix-community/nurl";
      changelog = "https://github.com/nix-community/nurl/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mpl20;
      mainProgram = pname;
    };
  }
