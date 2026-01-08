{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nurl";
    rev = "74f3e44604bb6b22f55f8dcc869f1685a1a050cf";
    version = "0.3.13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nurl";
      hash = "sha256-2/qahAH5G6JPq3TZ8b925Y9wCd1LoD7yzwcGbnuWUdI=";
    };

    cargoHash = "sha256-zVsab4sbi0J7pmjV9mf+Ozhyzvl0tgFXGTyLT9yORpw=";
    doCheck = false;

    meta = {
      description = "Generate Nix fetcher calls from repository URLs [maintainer=@figsoda";
      homepage = "https://github.com/nix-community/nurl";
      changelog = "https://github.com/nix-community/nurl/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mpl20;
      mainProgram = pname;
    };
  }
