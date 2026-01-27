{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nurl";
    rev = "bf2d2674650a16dcfd495b412620f67fd0b59576";
    version = "0.3.13-${rev}";

    src = fetchFromGitHub {
      inherit rev;
      owner = "nix-community";
      repo = "nurl";
      hash = "sha256-Cphpo0RnMTTCLWSlz08w8Hb6P+7iUHhJRY91loCR2a4=";
    };

    cargoHash = "sha256-VNsM2MXMZx3/Ttk4rxyW5CC4rq9PLHai6dmYZJo8FLA=";
    doCheck = false;

    meta = {
      description = "Generate Nix fetcher calls from repository URLs [maintainer=@figsoda";
      homepage = "https://github.com/nix-community/nurl";
      changelog = "https://github.com/nix-community/nurl/blob/${src.rev}/CHANGELOG.md";
      license = lib.licenses.mpl20;
      mainProgram = pname;
    };
  }
