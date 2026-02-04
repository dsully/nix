{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nurl";
    rev = "fb9a3da74b6cb2474974cc2f1aaa411c166dc2d7";
    version = "0.3.13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nurl";
      hash = "sha256-DIloaLQxNmFv3IhJIdo5y1gsizscM2Ucix5gqSkMmoM=";
    };

    cargoHash = "sha256-k678nkR/IIHDVa74ZLv0K41LNPfdjCa3BVpE1rRf4+I=";
    doCheck = false;

    meta = {
      description = "Generate Nix fetcher calls from repository URLs [maintainer=@figsoda";
      homepage = "https://github.com/nix-community/nurl";
      changelog = "https://github.com/nix-community/nurl/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mpl20;
      mainProgram = pname;
    };
  }
